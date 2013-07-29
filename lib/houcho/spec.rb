# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift '/Users/JP11546/Documents/houcho/lib'
require "houcho"
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


    def attach(specs, roles)
      free_path = specs.partition { |spec| File.exist?(spec) }
      under_repo = free_path[1].partition { |spec| File.exist?("#{@specdir}/#{spec}_spec.rb") }

      nofiles = free_path[1] + under_repo[1] - under_repo[0]
      raise SpecFileException, "No such spec file - #{nofiles.join(",")}" unless nofiles.empty?

      free_path[0].each do |spec|
        if File.exist?("#{@specdir}/#{spec.sub(/.+\/(.+)$/, '\1')}")
          raise SpecFileException, "Spec file of same name already exists in houcho spec directory - #{spec}"
        end
      end

      FileUtils.cp(free_path[0], @specdir)
      files = under_repo[0] + free_path[0].map { |s| s.sub(/.+\/(.+)\_spec\.rb$/, '\1') }
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
          @db.handle.execute("DELETE FROM #{@table} WHERE name = '#{spec}'")
          retry
        end
      end
    end
  end
end
