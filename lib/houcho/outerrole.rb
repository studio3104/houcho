require "houcho/element"

module Houcho
  class OuterRole < Element
    def initialize
      super("outerrole")
    end

    def details(outer_role)
      outer_role = outer_role.is_a?(Array) ? outer_role : [outer_role]
      result = {}
      outer_role.each do |role|
        hosts = hostlist(role)
        if !hosts.empty?
          result[role] = {}
          result[role]["host"] = hosts
        end
      end

      result
    end

    def hostlist(outer_role)
      outer_role = outer_role.is_a?(Array) ? outer_role : [outer_role]
      hosts = []

      outer_role.each do |role|
        id = id(role)
        hosts << @db.execute("
          SELECT host.name
          FROM host
          JOIN outerrole_host ORHOST
          ON host.id = ORHOST.host_id
          WHERE ORHOST.outerrole_id = ?
        ", id)
      end

      hosts.flatten.uniq.sort
    end
  end
end
