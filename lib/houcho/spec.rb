# -*- encoding: utf-8 -*-
require "#{File.expand_path("#{File.dirname(__FILE__)}/")}/element"

module Houcho
  class Spec
    @elements = YamlHandle::Editor.new('./role/specs.yaml')
    extend Element
  end
end
