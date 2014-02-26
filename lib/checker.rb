require 'onescreen-internal'
require 'nokogiri'
require 'yaml'
require 'faraday'

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

    def get_sites
      sites_obj = OneScreen::Internal::WebApp.all( :limit => 300 )
      setup_url(sites_obj)
    end

    def setup_url(sites_obj)
      sites_obj.map do |obj|
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
        #response = Faraday.get(site)
        puts site
        connection = Faraday.new
        connection.options.timeout = @timeout
        connection.options.open_timeout = @timeout

        response = connection.get site
        #puts response.status
        puts response.status
        is_site_up = response.status == 200
      rescue Exception => e
        puts e
        is_site_up = false
      end
=begin
      begin
        response = Net::HTTP.get_response(URI.parse(site))
        is_site_up = response.code == "200"
      rescue SocketError, Exception
        false
      end
=end
      is_site_up
    end

    def generate_report(result)
      # Generate a report for all sites' status
      down = up = 0
      result.each do |site, status|
        #puts "#{site}: #{status}"
        if status
          up += 1
        else
          down += 1
        end
      end
      puts "Up = #{up}\nDown = #{down}"
    end

  end

end

Adaptive::Checker.environment = "development"
Adaptive::Checker.timeout = 5
Adaptive::Checker::Initializers.init_os_api
