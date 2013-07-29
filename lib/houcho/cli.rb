$LOAD_PATH.unshift '/Users/JP11546/Documents/houcho/lib'

require 'houcho/cli/role'
require 'houcho/cli/spec'

module Houcho::CLI
  class Main < Thor
    register(Houcho::CLI::Role, 'role', 'role', 'chinko')
    register(Houcho::CLI::Spec, 'spec', 'spec', 'chinko')
  end
end
