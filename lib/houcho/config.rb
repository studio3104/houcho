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

    FILE = "#{Houcho::Config::APPROOT}/houcho.conf"
    begin
      conf = YAML.load_file(FILE)
    rescue
    end
    if conf
      UKIGUMO = conf["ukigumo"]
      IKACHAN = conf["ikachan"]
      GIT = conf["git"]
      RSPEC = conf["rspec"]
    end
  end
end
