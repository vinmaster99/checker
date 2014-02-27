require 'onescreen-internal'
require 'nokogiri'
require 'yaml'
require 'faraday'
require 'json'

require_relative "checker/initializers/api"

module Adaptive

  module Checker
    extend self

    attr_accessor :environment, :timeout

    def configuration
      config = YAML.load_file("config/onescreen.yml")

      if environment
        config[environment]
      else
        config['development']
      end
    end

    def get_sites( options = { :limit => 300, :include_widgets => true} )
      # get list of WebApp objects with widgets from OneScreen internal gem
      sites_obj = OneScreen::Internal::WebApp.all( options )
      setup_url(sites_obj)
    end

    def setup_url(sites_obj)
      # url from get_sites does not include protocal for valid request
      sites_obj.map do |obj|
        # obj is WebApp object
        domain = obj.domain
        unless domain.include? "http"
          domain = "http://"+domain
        else
          domain
        end
      end
    end

    def is_site_up?(site)
      is_site_up = false

      # check each site's status
      # if the site is up, then return true, otherwise false
      
      begin
        #response = Faraday.get(site)             # simple get request with Faraday
        connection = Faraday.new                  # Setup advance Faraday obj
        connection.options.timeout = @timeout     # set connection timeout
        connection.options.open_timeout = @timeout

        response = connection.get site            # make request
        #puts response.status
        is_site_up = response.status == 200
      rescue Exception => e
        is_site_up = false                        # any exception from request error on site
      end

      is_site_up
    end

    def generate_report(result)
      # Generate a report for all sites' status
      down = up = 0
      result.each do |site, status|
        if status
          up += 1
        else
          down += 1
        end
      end
      puts "Up = #{up}\nDown = #{down}"
    end

    def generate_json(result)
      puts result.to_json
    end

  end

end

Adaptive::Checker.environment = "development"
Adaptive::Checker.timeout = 5 # set connection timeout
Adaptive::Checker::Initializers.init_os_api
