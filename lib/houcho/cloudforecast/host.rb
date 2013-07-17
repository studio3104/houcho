# -*- encoding: utf-8 -*-
require "#{File.expand_path("#{File.dirname(__FILE__)}/")}/role"

module Houcho::CloudForecast
  module Host
    @cfdata = YamlHandle::Loader.new('./role/cloudforecast.yaml').data

    module_function

    def roles(host)
      @cfdata.select {|cfrole, cfhosts|cfhosts.include?(host)}.keys
    end

    def details(host)
      CloudForecast::Role.details(roles(host))
    end
  end
end
