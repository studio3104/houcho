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


    def check_existenxe(specs)
      files = specs.partition { |spec| File.exist?("#{@specdir}/#{spec}_spec.rb") }
      raise SpecFileException, "No such spec file - #{files[1].join(",")}" unless files[1].empty?

      files[0]
    end


    def attach(specs, roles)
      specs = [specs] unless specs.is_a?(Array)
      roles = [roles] unless roles.is_a?(Array)
      files = check_existenxe(specs)

      super(files, roles)
    end


    def delete_file(specs)
      specs.each do |spec|
        raise SpecFileException, "Spec file has been attached to role. - #{spec}" if attached?(spec)
        File.delete("#{@specdir}/#{spec}_spec.rb")
      end
    end


    def delete_file!(specs)
      specs.each do |spec|
        begin
          delete([spec])
        rescue SpecFileException
          @db.execute("DELETE FROM #{@table} WHERE name = ?", spec)
          retry
        end
      end
    end
  end
end
