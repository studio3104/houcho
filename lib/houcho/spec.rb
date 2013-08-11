require "houcho/role"
require "houcho/element"
require "houcho/config"

module Houcho
  class SpecFileException < Exception; end

  class Spec < Element
    def initialize
      super("serverspec")
      @specdir = Houcho::Config::SPECDIR
    end


    def check_existence(specs)
      specs = [specs] unless specs.is_a?(Array)
      files = specs.partition { |spec| File.exist?("#{@specdir}/#{spec}_spec.rb") }
      raise SpecFileException, "No such spec file - #{files[1].join(",")}" unless files[1].empty?

      files[0]
    end


    def attach(specs, roles)
      specs = [specs] unless specs.is_a?(Array)
      roles = [roles] unless roles.is_a?(Array)
      files = check_existence(specs)

      super(files, roles)
    end


    def rename(from, to)
      if File.exist?("#{@specdir}/#{to}_spec.rb")
        raise SpecFileException, "spec file already exist - #{to}"
      end

      check_existence(from)
      File.rename("#{@specdir}/#{from}_spec.rb", "#{@specdir}/#{to}_spec.rb")
      @db.execute("UPDATE #{@type} SET name = ? WHERE name = ?", to, from)
    end


    def delete(specs, force = false)
      specs = [specs] unless specs.is_a?(Array)

      detach_from_all(specs) if force

      @db.transaction do

      specs.each do |spec|
        begin
          @db.execute("DELETE FROM #{@type} WHERE name = ?", spec)
        rescue SQLite3::ConstraintException, "foreign key constraint failed"
          raise SpecFileException, "spec file has been attached to role - #{spec}"
        end
      end

      end #end of transaction

      begin
        check_existence(specs).each do |spec|
          File.delete("#{@specdir}/#{spec}_spec.rb")
        end
      rescue => e
        raise e.class, "#{e.message}" unless force
      end
    end


    def delete!(specs, force = true)
      delete(specs, true)
    end
  end
end
