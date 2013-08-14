require "yaml"

module Houcho
  module Config
    APPROOT = ENV["HOUCHO_ROOT"] ? ENV["HOUCHO_ROOT"] : "/etc/houcho"

    SPECDIR = "#{APPROOT}/spec"
    SCRIPTDIR = "#{APPROOT}/script"

    OUTERROLESOURCEDIR = "#{APPROOT}/outerrole"
    CFYAMLDIR = "#{OUTERROLESOURCEDIR}/cloudforecast"

    LOGDIR = "#{APPROOT}/log"
    SPECLOG = "#{LOGDIR}/serverspec.log"

    FILE = "#{APPROOT}/houcho.conf"
  end
end
