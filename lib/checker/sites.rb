module Adaptive

  module Checker
    extend self

    module Sites
      extend self
      attr_accessor :timeout

      def setup_domain(domain)
        # url from get_sites does not include protocal for valid request
        unless domain.include? "http"
          domain = "http://"+domain
        else
          domain
        end
      end

      def check_label(label_hash)
        label = label_hash[:label]
        if label.length > 0 && label[0] != '/'
          label_hash[:label] = '/'+label
        else
          label_hash[:label] = label
        end
        label_hash
      end
      
      def get_sites
        sites = Array.new
        # go page 1 to 10
        (1..10).each do |page_num|
          options = { :limit => 30, :include_widgets => true, :page => page_num }
          # get list of WebApp objects with widgets from OneScreen internal gem
          sites_obj = OneScreen::Internal::WebApp.all( options )

          sites_obj.each do |webapp|
            next if Adaptive::Checker.IGNORE_DOMAINS.include? webapp.domain
            next if webapp.is_deleted
            if webapp.widgets == []
              labels = []
            else
              labels = webapp.widgets.map { |widget| { :label => widget['label'], :status => false } unless widget['label'] == 'global' || widget['label'] == "" || widget['label'] == "/" || widget['is_deleted'] == true }.compact!
            end

            labels = [] if labels == nil
            labels.map! do |l|
              l = self.check_label(l)
            end
            puts labels.select { |x| x[:label][0] != '/' }.inspect

            sites << {
              :domain => self.setup_domain(webapp.domain),
              :status => false,
              :labels => labels,
              :cname => self.dig_check(webapp.domain)
            }
          end
        end
        sites
      end

      def check_sites(sites)
        sites.each do |site|
          domain = site[:domain]
          #domain_is_up = self.is_site_up?(domain)
          domain_is_up = self.get_status(domain)
          site[:status] = domain_is_up

          if domain_is_up != 404
            site[:labels].each do |label|
              #label[:status] = self.is_site_up?(domain+label[:label])
              label[:status] = self.get_status(domain+label[:label])
            end
          else
            site[:labels].each { |label| label[:status] = 404 }
          end
        end
        sites
      end

      def get_status(site)
        site_status = 404
        begin
          response = Faraday.head site
          site_status = response.status
        rescue Exception => e
          # site_status is already 404
          site_status = 404
        end
        site_status
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

      def dig_check(domain)
        check = %x(dig #{domain} | grep #{Adaptive::Checker.OS_CNAME})
        is_hosted = check.empty? ? false : true
      end

    end

  end

end
