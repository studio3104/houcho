# -*- encoding: utf-8 -*-
require "#{File.expand_path("#{File.dirname(__FILE__)}/")}/element"

module Houcho
  class Host
    @elements = YamlHandle::Editor.new('./role/hosts.yaml')
    extend Element
  end
end
