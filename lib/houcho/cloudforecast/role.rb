# -*- encoding: utf-8 -*-
require "#{File.expand_path("#{File.dirname(__FILE__)}/../")}/element"

module Houcho
  module CloudForecast
    class Role
      @elements = YamlHandle::Editor.new('./role/cf_roles.yaml')
      extend Element
    end
  end
end
