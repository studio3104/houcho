module Houcho
  module Role
    @roles = YamlHandle::Editor.new('./role/roles.yaml')

    module_function

    def create(role, exists = [])
      target = role.shift

      if self.index(target)
        exists << target
      else
        @roles.data[(@roles.data.keys.max||0) + 1] = target
      end

      if role.size == 0
        @roles.save_to_file
        abort("role(#{exists.join(',')}) already exist.") if exists.size != 0
      else
        self.create(role, exists)
      end
    end


    def delete(role, errors = {exists:[], hosts:[], specs:[], cf:[]})
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

      if role.size.zero?
        @roles.save_to_file
        e =  []
        e << "role(#{errors[:exists].join(',')}) does not exist" if ! errors[:exists].size.zero?
        e << "detach host from #{errors[:hosts].join(',')} before delete" if ! errors[:hosts].size.zero?
        e << "detach spec from #{errors[:specs].join(',')} before delete" if ! errors[:specs].size.zero?
        e << "detach cloudforecast's role from #{errors[:cf].join(',')} before delete" if ! errors[:cf].size.zero?
        abort("#{e.join(', ')}.") if ! e.size.zero?
      else
        self.delete(role, errors)
      end
    end


    def rename(role, name)
      index = self.index(role)
      abort("#{role} does not exist") if ! index
      abort("#{name} already exist") if self.index(name)

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
          self.indexes_regexp(Regexp.new(role)).map {|index|self.name(index)}
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
      @roles.data.select {|index, rolename| rolename =~ role }.keys
    end


    def name(index)
      @roles.data[index]
    end
  end
end
