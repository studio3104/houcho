# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift '/Users/JP11546/Documents/houcho/lib'

require "houcho/database"

module Houcho
  class RoleExistenceException < Exception; end

  class Role
    def initialize
      @db = Houcho::DB.new.handle
    end


    def id(role)
      @db.execute("SELECT id FROM role WHERE name = '#{role}'").flatten.first
    end


    def exist?(role)
      !id(role).nil?
    end


    def create(role)
      role = [role] unless role.is_a?(Array)

      @db.transaction do
        role.each do |r|
          begin
            @db.execute("INSERT INTO role(name) VALUES('#{r}')")
          rescue SQLite3::ConstraintException, "column name is not unique"
            raise RoleExistenceException, "role already exist - #{r}"
          end
        end
      end
    end


    def delete(role)
      role = [role] unless role.is_a?(Array)

      @db.transaction do
        role.each do |r|
          raise RoleExistenceException, "role does not exist - #{r}" unless exist?(r)
          @db.execute("DELETE FROM role WHERE name = '#{r}'")
        end
      end
    end


    def rename(exist_role, name)
      raise RoleExistenceException, "role does not exist - #{exist_role}" unless exist?(exist_role)
      raise RoleExistenceException, "role already exist - #{name}" if exist?(name)
      @db.execute("UPDATE role SET name = '#{name}' WHERE name = '#{exist_role}'")
    end


    def list
      @db.execute("SELECT name FROM role").flatten
    end
  end
end

__END__



    def all
      YamlHandle::Loader.new('./role/roles.yaml').data.values.sort
    end




    def index(role)
      @data.invert[role]
    end


    def indexes_regexp(role)
      @roles.data.select { |index, rolename| rolename =~ role }.keys
    end


    def name(index)
      @roles.data[index]
    end


    def details(roles)
      result = {}

      # too lengthy implementation... I think necessary to change...
      roles = roles.map do |role|
        if self.index(role)
          role
        else
          self.indexes_regexp(Regexp.new(role)).map { |index| self.name(index) }
        end
      end.flatten.sort.uniq

      roles.each do |role|
        index = self.index(role)
        next if ! index

        hosts   = Host.elements(index)
        specs   = Spec.elements(index)
        cfroles = CloudForecast::Role.elements(index)
        cfhosts = CloudForecast::Role.details(cfroles)

        r         = {}
        r['host'] = hosts   if ! hosts.empty?
        r['spec'] = specs   if ! specs.empty?
        r['cf']   = cfhosts if ! cfhosts.empty?

        result[role] = r
      end

      result
    end
  end
end
