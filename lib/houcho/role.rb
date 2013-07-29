# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift '/Users/JP11546/Documents/houcho/lib'

require "houcho/database"

module Houcho
  class Role
    def initialize
      @db = Houcho::DB.new
    end


    def id(role)
      @db.handle.execute("SELECT id FROM role WHERE name = '#{role}'")
    end


    def exist?(role)
      # 存在しないroleを削除しようとしたりしてもエラんないから、コイツを使ってエラるように実装しようかな、と。
      # 対象は delete と rename
      !id.empty?
    end


    def create(role)
      role = [role] unless role.is_a?(Array)

      @db.handle.transaction do
        role.each do |r|
          @db.handle.execute("INSERT INTO role(name) VALUES('#{r}')")
        end
      end
    end


    def delete(role)
      role = [role] unless role.is_a?(Array)

      @db.handle.transaction do
        role.each do |r|
          @db.handle.execute("DELETE FROM role WHERE name = '#{r}'")
        end
      end
    end


    def rename(exist_role, name)
      @db.handle.execute("UPDATE role SET name = '#{name}' WHERE name = '#{exist_role}'")
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
