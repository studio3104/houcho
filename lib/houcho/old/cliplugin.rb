$LOAD_PATH.unshift '/Users/JP11546/Documents/houcho/lib'

module Houcho::CLI

class Role < Thor
  require 'houcho/role'
  namespace :role

  desc 'attach [host1 host2 host3...] --roles [role1 role2...]', 'attach host to role'
  option :roles, :type => :array, :required => true, :desc => 'specify the roles separated by spaces.'
  def attach(*args)
    Houcho::Host.attach(args, options[:roles])
  rescue RuntimeError => e
    puts e.message
    exit!
  end
end

class Sub < Thor
  register(Houcho::CLI::Role, 'role', 'role', 'chinko')
end


end
