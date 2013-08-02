# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift '/Users/JP11546/Documents/houcho/lib'
require "houcho"
require "houcho/element"

module Houcho
  class Host < Element
    def initialize
      super("host")
    end

=begin
    def details(hosts)
      result  = {}

      hosts.each do |host|
        roles = self.indexes(host).map {|index|Role.name(index)}
        cfroles = CloudForecast::Host.new.roles(host)

        result[host]         = {}
        result[host]['role'] = roles   if ! roles.empty?
        result[host]['cf']   = cfroles if ! cfroles.empty?

        result.delete(host) if result[host].keys.empty?
      end
      result
    end
=end
  end
end
