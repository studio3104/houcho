# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift '/Users/JP11546/Documents/houcho/lib'
require "houcho"
require "houcho/element"

module Houcho
  class OuterRole < Element
    def initialize
      super("outerrole")
    end
  end
end
