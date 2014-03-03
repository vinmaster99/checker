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
      
      def get_sites
        sites = Array.new
        # go page 1 to 10
        (1..10).each do |page_num|
          options = { :limit => 30, :include_widgets => true, :page => page_num }
          # get list of WebApp objects with widgets from OneScreen internal gem
          sites_obj = OneScreen::Internal::WebApp.all( options )

          sites_obj.each do |webapp|
            if webapp.widgets == []
              labels = []
            else
              labels = webapp.widgets.map { |widget| { :label => widget['label'], :status => false } unless widget['label'] == 'global' || widget['label'] == "" || widget['label'] == "/" }.compact!
            end

            labels = [] if labels == nil

            sites << {
              :domain => self.setup_url(webapp.domain),
              :status => false,
              :labels => labels
            }
          end
        end
        sites
      end

      def check_sites(sites)
        sites.each do |site|
          domain = site[:domain]
          domain_is_up = self.is_site_up?(domain)
          site[:status] = domain_is_up

          if domain_is_up
            site[:labels].each do |label|
              label[:status] = self.is_site_up?(domain+label[:label])
              #site[:status] &= label[:status]   # if one of the subdomain is down, mark domain as down
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
          # simple get request with Faraday
          #response = Faraday.get(site)

          # setup Faraday obj with options
          #connection = Faraday.new
          #connection.options.timeout = @timeout     # set connection timeout
          #connection.options.open_timeout = @timeout
          #response = connection.get site            # make request
          
          # Use Faraday to get header
          response = Faraday.head site
          is_site_up = response.status == 200       # if it returns 200, it is up
        rescue Exception => e
          is_site_up = false                        # any exception from request error on site
        end

        is_site_up
      end

    end

  end

end
