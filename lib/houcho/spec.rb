module Houcho
  class Spec
    @elements = YamlHandle::Editor.new('./role/specs.yaml')
    extend Element
  end
end
