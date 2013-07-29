# -*- encoding: utf-8 -*-

require 'houcho/role'

module Houcho
  module Element

    def elements(index = nil)
      if index
        (@elements.data[index]||[]).uniq
      else
        @elements.data.values.flatten.uniq
      end
    end


    def attach(elements, roles)
      elements = [elements] if elements.class == String
      roles    = [roles]    if roles.class    == String

      invalid_roles = []
      roles.each do |role|
        index = Role.index(role)
        if ! index
          invalid_roles << role
          next
        end

        @elements.data[index] ||= []
        @elements.data[index] = (@elements.data[index] + elements).sort.uniq
      end

      @elements.save_to_file
      raise("role(#{invalid_roles.join(',')}) does not exist") if invalid_roles.size != 0
    end


    def detach(elements, roles)
      elements = [elements] if elements.class == String
      roles    = [roles]    if roles.class    == String

      invalid_roles = []
      roles.each do |role|
        index = Role.index(role)
        if ! index
          invalid_roles << role
          next
        end

        @elements.data[index].delete(elements)
      end

      @elements.save_to_file
      raise("role(#{invalid_roles.join(',')}) does not exist") if invalid_roles.size != 0
    end


    def attached?(index, element)
      return false if ! @elements.data.has_key?(index)
      @elements.data[index].include?(element)
    end


    def has_data?(index)
      return false if ! @elements.data.has_key?(index)
      @elements.data[index].size != 0
    end


    def indexes(element)
      return [] if ! @elements.data.values.flatten.include?(element)
      @elements.data.select { |index, elems| elems.include?(element) }.keys
    end


    def details(elements)
      result = {}
      elements.each do |element|
        result[element] = { 'role' => self.indexes(element).map { |index| Role.name(index) } }
      end
      result
    end
  end
end
