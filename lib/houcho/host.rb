# -*- encoding: utf-8 -*-
require "#{File.expand_path("#{File.dirname(__FILE__)}/")}/yamlhandle"

module Houcho
  module Host
    @elements  = YamlHandle::Editor.new('./role/hosts.yaml')

    module_function

    def test
      puts 1234
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
end
