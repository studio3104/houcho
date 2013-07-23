$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'houcho'
require 'houcho/yamlhandle'
require 'houcho/element'
require 'houcho/role'
require 'houcho/host'
require 'houcho/spec'
require 'houcho/spec/runner'
require 'houcho/cloudforecast'
require 'houcho/cloudforecast/role'
require 'houcho/cloudforecast/host'
require 'houcho/ci'
require 'tmpdir'
require 'tempfile'
require 'fileutils'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  
end
