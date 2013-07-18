module Houcho
  module CloudForecast
    class Role
      @elements = YamlHandle::Editor.new('./role/cf_roles.yaml')
      extend Element

      def self.details(cfroles)
        result = {}
        cfroles.each do |cfrole|
          hosts = CloudForecast::Host.hosts(cfrole)
          if ! hosts.empty?
            result[cfrole] = {}
            result[cfrole]['host'] = hosts
          end
        end
        result
      end
    end
  end
end
