require "houcho/element"
require "houcho/attribute"

module Houcho
  class OuterRoleExistenceException < Exception; end

  class OuterRole < Element
    include Houcho::Attribute

    def initialize
      super("outerrole")
      @type_id = 1
    end


    def list(opt = {})
      sql = "SELECT T1.name FROM outerrole T1, role_outerrole T2"
      sql += " WHERE T1.data_source LIKE ?"
      ds = opt[:data_source]

      if opt[:role_id]
        sql += " AND T1.id = T2.outerrole_id AND T2.role_id = ?"
        return @db.execute(sql, ds ? ds : "%", opt[:role_id]).flatten
      else
        return @db.execute(sql, ds ? ds : "%").flatten
      end
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

    private
    def raise_target_does_not_exist(target)
      raise OuterRoleExistenceException, "outer role does not exist - #{target}"
    end
  end
end
