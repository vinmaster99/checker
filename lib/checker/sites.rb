module Adaptive

  module Checker
    extend self

    module Sites
      extend self
      attr_accessor :timeout

      def setup_url(domain)
        # url from get_sites does not include protocal for valid request
        unless domain.include? "http"
          domain = "http://"+domain
        else
          domain
        end
      end
      
      def get_sites( options = { :limit => 300, :include_widgets => true} )
        # get list of WebApp objects with widgets from OneScreen internal gem
        sites_obj = OneScreen::Internal::WebApp.all( options )
        #setup_url(sites_obj)
        sites = Array.new
        sites_obj.each do |webapp|
          labels = webapp.widgets.map { |widget| { 'label' => widget['label'], 'status' => false } unless widget['label'] == 'global' || widget['label'] == "" || widget['label'] == "/" }.compact!
          site = Hash.new
          site['domain'] = self.setup_url(webapp.domain)
          site['status'] = false
          site['labels'] = labels
          sites << site
        end
        sites
      end

      def check_sites(sites)
        sites.each do |site|
          domain = site['domain']
          domain_is_up = self.is_site_up?(domain)
          site['status'] = domain_is_up

          if domain_is_up
            site['labels'].each do |label|
              label['status'] = self.is_site_up?(domain+label['label'])
            end
          else
            next
          end
        end
        sites
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
          is_site_up = response.status == 200       # if it returns 200, it is up
        rescue Exception => e
          is_site_up = false                        # any exception from request error on site
        end

        is_site_up
      end

    end

  end

end
