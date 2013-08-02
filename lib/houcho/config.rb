require "toml"

module Houcho
  module Config
    APPROOT = ENV["HOUCHO_ROOT"] ? ENV["HOUCHO_ROOT"] : "#{File.expand_path("~")}/houcho"
    SPECDIR = "#{APPROOT}/spec"
    SCRIPTDIR = "#{APPROOT}/script"
    OUTERROLESOURCEDIR = "#{APPROOT}/outerrole"
    CFYAMLDIR = "#{OUTERROLESOURCEDIR}/cloudforecast"
  end
end
