module Houcho
  module CloudForecast::Host
    @cfdata = YamlHandle::Loader.new('./role/cloudforecast.yaml').data

    module_function

    def roles(host)
      @cfdata.select {|cfrole, cfhosts|cfhosts.include?(host)}.keys
    end

    def hosts(role)
      @cfdata[role] || []
    end

    def details(host)
      CloudForecast::Role.details(roles(host))
    end

    def all
      @cfdata.values.flatten.uniq
    end
  end
end
