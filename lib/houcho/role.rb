require 'houcho/yamlhandle'
require 'houcho/host'
require 'houcho/spec'
require 'houcho/cloudforecast/role'

module Houcho
  module Role
    @roles = YamlHandle::Editor.new('./role/roles.yaml')

    module_function

    def create(role, exists = [])
      role   = [role] if role.class == String
      target = role.shift

      if self.index(target)
        exists << target
      else
        @roles.data[(@roles.data.keys.max||0) + 1] = target
      end

      if role.size == 0
        @roles.save_to_file
        raise("role(#{exists.join(',')}) already exist.") if exists.size != 0
      else
        self.create(role, exists)
      end
    end


    def delete(role, errors = {exists:[], hosts:[], specs:[], cf:[]})
      role   = [role] if role.class == String
      target = role.shift
      index  = self.index(target)
      del    = true

      if ! index
        errors[:exists] << target; del = false
      end
      if Host.has_data?(index)
        errors[:hosts] << target if Host.has_data?(index); del = false
      end
      if Spec.has_data?(index)
        errors[:specs] << target if Spec.has_data?(index); del = false
      end
      if CloudForecast::Role.has_data?(index)
        errors[:cf] << target if CloudForecast::Role.has_data?(index); del = false
      end

      @roles.data.delete(index) if del

      if role.size == 0
        @roles.save_to_file
        e =  []
        e << "role(#{errors[:exists].join(',')}) does not exist" if errors[:exists].size != 0
        e << "detach host from #{errors[:hosts].join(',')} before delete" if errors[:hosts].size != 0
        e << "detach spec from #{errors[:specs].join(',')} before delete" if errors[:specs].size != 0
        e << "detach cloudforecast's role from #{errors[:cf].join(',')} before delete" if errors[:cf].size != 0
        raise("#{e.join(', ')}.") if e.size != 0
      else
        self.delete(role, errors)
      end
    end


    def rename(role, name)
      index = self.index(role)
      raise("#{role} does not exist") if ! index
      raise("#{name} already exist") if self.index(name)

      @roles.data[index] = name
      @roles.save_to_file
    end


    def all
      YamlHandle::Loader.new('./role/roles.yaml').data.values.sort
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


    def index(role)
      @roles.data.invert[role]
    end


    def indexes_regexp(role)
      @roles.data.select { |index, rolename| rolename =~ role }.keys
    end


    def name(index)
      @roles.data[index]
    end


    def exist?(role)
      ! self.index(role).nil?
    end
  end
end
