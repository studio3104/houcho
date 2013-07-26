require 'houcho/yamlhandle'
require 'houcho/role'
require 'houcho/element'

module Houcho
  class Spec
    @elements = YamlHandle::Editor.new('./role/specs.yaml')
    extend Element

    def self.partition(specs)
      free_path  = specs.partition { |spec| File.exist?(spec) }
      under_repo = free_path[1].map { |spec| 'spec/' + spec + '_spec.rb' }.partition { |spes| File.exist?(spes) }

      [free_path[0] + under_repo[0], under_repo[1].map { |e|e.sub(/^spec\//,'').sub(/_spec.rb$/,'') }]
    end

    def self.attach(specs, roles)
      specs = [specs] if specs.class == String
      roles = [roles] if roles.class == String

      invalid_roles = []
      roles.each do |role|
        index = Role.index(role)
        if ! index
          invalid_roles << role
          next
        end

        @elements.data[index] ||= []
        @elements.data[index] = (@elements.data[index] + specs).sort.uniq
      end

      @elements.save_to_file
      raise("role(#{invalid_roles.join(',')}) does not exist") if invalid_roles.size != 0
    end
  end
end
