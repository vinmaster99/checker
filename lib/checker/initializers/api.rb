module Adaptive

  module Checker

    module Initializers
      extend self

      def init_os_api
        OneScreen.api_root = Adaptive::Checker.configuration['onescreen']['api']['root']
        OneScreen.api_version = Adaptive::Checker.configuration['onescreen']['api']['version']
      end

    end

  end

end
