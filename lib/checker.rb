require 'onescreen-internal'
require 'nokogiri'
require 'yaml'
require 'faraday'
require 'json'

require_relative "checker/sites"
require_relative "checker/initializers/api"

module Adaptive

  module Checker
    extend self

    attr_accessor :environment, :OS_CNAME, :IGNORE_DOMAINS

    def configuration
      config = YAML.load_file("config/onescreen.yml")

      if environment
        config[environment]
      else
        config['development']
      end
    end

    def generate_report(result)
      # Generate a report for all sites' status
      down = up = 0
      result.each do |site|
        if site[:status] != 404
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
Adaptive::Checker::Sites.timeout = 10 # set connection timeout
Adaptive::Checker::Initializers.init_os_api
Adaptive::Checker.OS_CNAME = "sites1.onescreen.net"
Adaptive::Checker.IGNORE_DOMAINS = ['sites-status.net', 'testing.jwplayer.com', 'testing', 'layouttesting', 'global', 'sample.sites.com', 'testing.jekyll.com', 'testing_upload']
