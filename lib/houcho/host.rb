# -*- encoding: utf-8 -*-
require "#{File.expand_path("#{File.dirname(__FILE__)}/")}/element"
require "#{File.expand_path("#{File.dirname(__FILE__)}/")}/cloudforecast/host"

module Houcho
  class Host
    @elements = YamlHandle::Editor.new('./role/hosts.yaml')
    extend Element

    def self.details(elements)
      require 'awesome_print'
      result  = {}

      elements.each do |element|
        cfhostdetails = CloudForecast::Host.details(element)
        hostdetails   = Role.details(indexes(element))

        cfhostdetails.clone.each do |cfrole, values|
          cfhostdetails.delete(cfrole) if hostdetails == values
        end

        result[element] = hostdetails.merge(cfhostdetails)
        result.delete(element) if result[element].empty?
      end
      result
    end
  end
end
