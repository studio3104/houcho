# -*- encoding: utf-8 -*-
class RoleHandle
  require 'yaml'
  require 'tempfile'
  require 'find'
end

class RoleHandle
  class YamlLoader
    attr_reader :data

    def initialize(yaml_file)
      @data = YAML.load_file(yaml_file)
      @data ||= {}
    end
  end

  class YamlEditor < YamlLoader
    attr_accessor :data

    def initialize(yaml_file)
      super
      @yaml_file = yaml_file
    end

    def save_to_file
      open(@yaml_file, 'w') do |f|
        YAML.dump(@data, f)
      end
    end
  end

  class ElementHandler
    def initialize(yaml)
      @elements  = YamlEditor.new(yaml)
    end

    def elements(index = nil)
      if index
        (@elements.data[index]||[]).uniq
      else
        @elements.data.values.flatten.uniq
      end
    end

    def attach(index, element)
      @elements.data[index] ||= []
      @elements.data[index] << element
      @elements.save_to_file
    end

    def detach(index, element)
      @elements.data[index].delete(element)
      @elements.save_to_file
    end

    def attached?(index, element)
      return false if ! @elements.data.has_key?(index)
      @elements.data[index].include?(element)
    end

    # roleを消そうとしているオブジェクトからの問い合わせ用
    def has_data?(index)
      return false if ! @elements.data.has_key?(index)
      @elements.data[index].size != 0
    end

    def indexes(element)
      return [] if ! @elements.data.values.flatten.include?(element)
      @elements.data.select {|index, elems|elems.include?(element)}.keys
    end
  end

  class RoleHandler
    def initialize(yaml)
      @roles = YamlEditor.new(yaml)
    end

    def create(role)
      @roles.data[(@roles.data.keys.max||0) + 1] = role
      @roles.save_to_file
    end

    def delete(id)
      @roles.data.delete(id)
      @roles.save_to_file
    end

    def rename(id, name)
      @roles.data[id] = name
      @roles.save_to_file
    end

    def index(role)
      @roles.data.invert[role]
    end

    def indexes_regexp(role)
      @roles.data.select {|index, rolename| rolename =~ role }.keys
    end

    def name(id)
      @roles.data[id]
    end
  end

  class CfLoader
    attr_reader :role_hosts

    def initialize(yaml_file)
      @role_hosts = {}
      elements    = {}
      group       = []
      File.open(yaml_file) do |f|
        f.each do |l|
          if l =~ /^---/
            if l =~ /^---\s+#(.+)$/
              group << $1.gsub(/\s/, '_')
            else
              group << 'NOGROUPNAME'
            end
          end
        end
      end
      File.open(yaml_file) do |f|
        i=0
        YAML.load_documents(f) do |data|
          elements[group[i]] ||= []
          elements[group[i]].concat data['servers']
          i+=1
        end
      end

      elements.each do |groupname, data|
        current_label = 'NOCATEGORYNAME'

        data.each do |d|
          if ! d['label'].nil?
            label = d['label'].gsub(/\s/, '_')
            current_label = label if current_label != label
          end

          d['hosts'].map! do |host|
            host = host.split(' ')
            host = host.size == 1 ? host[0] : host[1]
          end

          r = groupname + '::' + current_label + '::' + d['config'].sub(/\.yaml$/, '')
          ary = (@role_hosts[r] || []) | d['hosts']
          @role_hosts[r] = ary.uniq
        end
      end
    end
  end
end
