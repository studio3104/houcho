require 'houcho/yamlhandle'
require 'houcho/element'
require 'houcho/role'
require 'houcho/cloudforecast/host'

module Houcho
  class Host
    @elements = YamlHandle::Editor.new('./role/hosts.yaml')
    extend Element

    def self.details(hosts)
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
  end
end