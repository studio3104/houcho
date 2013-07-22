module Houcho
  module CloudForecast
    class Host
      def initialize
        @cf = YamlHandle::Loader.new('./role/cloudforecast.yaml')
      end

      def roles(host)
        @cf.data.select {|cfrole, cfhosts|cfhosts.include?(host)}.keys
      end

      def hosts(role)
        @cf.data[role] || []
      end

      def details(host)
        CloudForecast::Role.details(roles(host))
      end

      def all
        @cf.data.values.flatten.uniq
      end
    end
  end
end
