$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require "tmpdir"
spectmp = Dir.mktmpdir("houcho")
ENV["HOUCHO_ROOT"] = spectmp

require "rspec"
require "houcho"
require "fileutils"

describe Houcho do
  before :all do
    Houcho::Repository.init

    File.write("#{Houcho::Config::CFYAMLDIR}/cf.yaml", <<YAML
--- #houcho
servers:
  - label: rspec
    config: studio3104
    hosts:
      - 192.168.1.11 test1.studio3104.com
      - 192.168.1.12 test2.studio3104.com
YAML
    )

    File.write("#{Houcho::Config::SPECDIR}/specA_spec.rb"," ")
    File.write("#{Houcho::Config::SPECDIR}/specB_spec.rb"," ")
    File.write("#{Houcho::Config::SPECDIR}/specC_spec.rb"," ")

    @role = Houcho::Role.new
    @host = Houcho::Host.new
    @spec = Houcho::Spec.new
    @outerrole = Houcho::OuterRole.new
    @specrunner = Houcho::Spec::Runner.new

    @role.create(["studio3104", "studio3105"])

    Houcho::OuterRole::CloudForecast.load

    @host.attach("hostA", "studio3104")
    @outerrole.attach("houcho::rspec::studio3104", "studio3104")
    @spec.attach("specA", "studio3104")
  end


  after :all do
    FileUtils.rm_rf(spectmp)
  end


  describe Houcho::Role do
    context "create and delete a role" do
      it { @role.create("www") }
      it { @role.delete("www") }

      it do
        expect { @role.create("studio3104") }.to(
          raise_error(Houcho::RoleExistenceException, "role already exist - studio3104")
        )
      end

      it do
        expect { @role.delete("web") }.to(
          raise_error(Houcho::RoleExistenceException, "role does not exist - web")
        )
      end
    end


    context "create and delete two roles" do
      it { @role.create(["studio3104::www", "studio3104::database"]) }
      it { @role.delete(["studio3104::www", "studio3104::database"]) }

      it do
        expect { @role.create(["studio3104", "studio3105"]) }.to(
          raise_error(Houcho::RoleExistenceException, "role already exist - studio3104")
        )
      end

      it do
        expect { @role.delete(["studio3104::www", "studio3104::database"]) }.to(
          raise_error(Houcho::RoleExistenceException, "role does not exist - studio3104::www")
        )
      end
    end


    context "rename a role" do
      it { @role.rename("studio3105", "studio3106") }

      it do
        expect { @role.rename("invalid_role", "studio3106") }.to(
          raise_error(Houcho::RoleExistenceException, "role does not exist - invalid_role")
        )
      end

      it do
        expect { @role.rename("studio3106", "studio3104") }.to(
          raise_error(Houcho::RoleExistenceException, "role already exist - studio3104")
        )
      end

      it { @role.rename("studio3106", "studio3105") }
    end


    context "get all roles" do
      it { expect(@role.list).to eq(["studio3104", "studio3105"]) }
    end


    context "get details of a role" do
      it do
        expect(@role.details(["studio3104"])).to eq(
          {
            "studio3104" => {
              "host"       => [ "hostA" ],
              "spec"       => [ "specA" ],
              "outer role" => {
                "houcho::rspec::studio3104" => {
                  "host" => [ "test1.studio3104.com", "test2.studio3104.com" ] 
                }
              }
            }
          }
        )
      end
    end

    it { expect(@role.id("studio3104")).to be(1)}
    it { expect(@role.id(/studio310\d/)).to eq([1,2])}
    it { expect(@role.name(1)).to eq("studio3104")}

    context "set, get and delete attribute of a role" do
      it { @role.set_attr("studio3104", { A: "apple", B: "banana", C: "chocolate" }) }
      it { expect(@role.get_attr("studio3104")).to eq({ A: "apple", B: "banana", C: "chocolate" }) }
      it { expect(@role.get_attr_json("studio3104")).to eq("{\"A\":\"apple\",\"B\":\"banana\",\"C\":\"chocolate\"}") }
      it { expect(@role.get_attr("studio3104", "A")).to eq({ A: "apple" }) }
      it { expect(@role.get_attr("invalid_role")).to eq({}) }
      it { expect(@role.get_attr_json("invalid_role")).to eq("{}") }

      it { expect { @role.set_attr("studio3104", { "A" => "anpanman" }) }.to(
        raise_error(Houcho::AttributeExceptiotn, "attribute has already defined value in role - A")
      )}

      it "force set" do
        expect(@role.set_attr!("studio3104", { "A" => "anpanman" }))
      end

      it { expect { @role.set_attr("invalid_role",{ A: "apple", B: "banana", C: "chocolate" }) }.to(
        raise_error(Houcho::RoleExistenceException, "role does not exist - invalid_role") 
      ) }

      it { expect(@role.del_attr("studio3104", "C")).to eq({ :C => "chocolate" }) }
      it { expect(@role.get_attr("studio3104")).to eq({ A: "anpanman", B: "banana" }) }
      it { expect(@role.del_attr("studio3104")).to eq({ A: "anpanman", B: "banana" }) }
      it { expect(@role.get_attr("studio3104")).to eq({}) }
    end
  end


  describe Houcho::Host do
    context "attach and detach hosts to roles" do
      it { @host.attach(["host1", "host2"], ["studio3104", "studio3105"]) }
      it { @host.detach(["host1", "host2"], ["studio3104", "studio3105"]) }

      it do
        expect { @host.attach("host1", "invalid_role") }.to(
          raise_error(Houcho::RoleExistenceException, "role does not exist - invalid_role")
        )
      end

      it do
        expect { @host.detach("host1", "invalid_role") }.to(
          raise_error(Houcho::RoleExistenceException, "role does not exist - invalid_role")
        )
      end
    end

    context "get details of a host" do
      it "host from original defined" do
        expect(@host.details(["hostA"])).to eq(
          { "hostA" => { "role" => [ "studio3104" ] } }
        )
      end

      it "host from cf defined" do
        expect(@host.details(["test1.studio3104.com"])).to eq(
          { "test1.studio3104.com" => { "outer role" => [ "houcho::rspec::studio3104" ] } }
        )
      end

      it "both" do
        expect(@host.details(["hostA", "test1.studio3104.com"])).to eq(
          {
            "hostA"                => { "role" => [ "studio3104" ] },
            "test1.studio3104.com" => { "outer role" => [ "houcho::rspec::studio3104" ] },
          }
        )
      end
    end

    context "get host list attached or defined cf" do
      it "all of hosts" do
        expect(@host.list).to eq(["test1.studio3104.com", "test2.studio3104.com", "hostA"])
      end

      it "hosts of one of role" do
        expect(@host.list(1)).to eq(["hostA"])
      end
    end

    context "set, get and delete attribute of a host" do
      it { @host.set_attr("hostA", { A: "apple", B: "banana", C: "chocolate" }) }
      it { expect(@host.get_attr("hostA")).to eq({ A: "apple", B: "banana", C: "chocolate" }) }
      it { expect(@host.get_attr_json("hostA")).to eq("{\"A\":\"apple\",\"B\":\"banana\",\"C\":\"chocolate\"}") }
      it { expect(@host.get_attr("hostA", "A")).to eq({ A: "apple" }) }
      it { expect(@host.get_attr("hostX")).to eq({}) }
      it { expect(@host.get_attr_json("hostX")).to eq("{}") }

      it { expect { @host.set_attr("hostA", { "A" => "anpanman" }) }.to(
        raise_error(Houcho::AttributeExceptiotn, "attribute has already defined value in host - A")
      )}

      it "force set" do
        expect(@host.set_attr!("hostA", { "A" => "anpanman" }))
      end

      it { expect { @host.set_attr("hostX",{ A: "apple", B: "banana", C: "chocolate" }) }.to(
        raise_error(Houcho::HostExistenceException, "host does not exist - hostX") 
      ) }

      it { expect(@host.del_attr("hostA", "C")).to eq({ :C => "chocolate" }) }
      it { expect(@host.get_attr("hostA")).to eq({ A: "anpanman", B: "banana" }) }
      it { expect(@host.del_attr("hostA")).to eq({ A: "anpanman", B: "banana" }) }
      it { expect(@host.get_attr("hostA")).to eq({}) }
    end
  end


  describe Houcho::Spec do
    context "get details of a spec" do
      it "host from original defined" do
        expect(@spec.details(["specA"])).to eq(
          { "specA" => { "role" => [ "studio3104" ] } }
        )
      end
    end

    context "attach and detach hosts to roles" do
      it { @spec.attach(["specA", "specB"], ["studio3104", "studio3105"]) }
      it { @spec.detach("specB", ["studio3104", "studio3105"]) }

      it do
        expect { @spec.attach("specA", "invalid_role") }.to(
          raise_error(Houcho::RoleExistenceException, "role does not exist - invalid_role")
        )
      end

      it do
        expect { @spec.detach("specA", "invalid_role") }.to(
          raise_error(Houcho::RoleExistenceException, "role does not exist - invalid_role")
        )
      end

      it do
        expect { @spec.attach("invalid_spec", "studio3104") }.to(
          raise_error(Houcho::SpecFileException, "No such spec file - invalid_spec")
        )
      end
    end

    context "delete spec file" do
      it {
        @spec.check_existence("specC")
        @spec.delete("specC")
        expect { @spec.check_existence("specC") }.to(
          raise_error(Houcho::SpecFileException, "No such spec file - specC")
        )
      }
      it { expect { @spec.delete("specX") }.to(
        raise_error(Houcho::SpecFileException, "No such spec file - specX")
      ) }
      it { expect { @spec.delete("specA") }.to(
        raise_error(Houcho::SpecFileException,"spec file has been attached to role - specA")
      ) }
      it "force delete" do
        @spec.check_existence("specA")
        @spec.delete!("specA")
        expect { @spec.check_existence("specA") }.to(
          raise_error(Houcho::SpecFileException, "No such spec file - specA")
        )
      end
      it {
        File.write("#{Houcho::Config::SPECDIR}/specA_spec.rb"," ") 
        File.write("#{Houcho::Config::SPECDIR}/specC_spec.rb"," ") 
        @spec.attach("specA", ["studio3104", "studio3105"])
      }
    end

    context "rename a spec file" do
      it { @spec.rename("specC", "specSE") }

      it { expect { @spec.rename("specX", "specXXX") }.to(
          raise_error(Houcho::SpecFileException, "No such spec file - specX")
      ) }

      it { expect { @spec.rename("specSE", "specA") }.to(
          raise_error(Houcho::SpecFileException, "spec file already exist - specA")
      ) }

      it { @spec.rename("specSE", "specC") }
    end
  end


  describe Houcho::OuterRole do
    context "set, get and delete attribute of a role" do
      it { @outerrole.set_attr(
        "houcho::rspec::studio3104",
        { A: "apple", B: "banana", C: "chocolate" }
      ) }
      it { expect(@outerrole.get_attr("houcho::rspec::studio3104")).to(
        eq({ A: "apple", B: "banana", C: "chocolate" })
      ) }
      it { expect(@outerrole.get_attr_json("houcho::rspec::studio3104")).to(
        eq("{\"A\":\"apple\",\"B\":\"banana\",\"C\":\"chocolate\"}")
      ) }
      it { expect(@outerrole.get_attr("houcho::rspec::studio3104", "A")).to(
        eq({ A: "apple" })
      ) }
      it { expect(@outerrole.get_attr("invalid_role")).to eq({}) }
      it { expect(@outerrole.get_attr_json("invalid_role")).to eq("{}") }

      it { expect { @outerrole.set_attr(
        "houcho::rspec::studio3104", { "A" => "anpanman" }
      ) }.to(
        raise_error(
          Houcho::AttributeExceptiotn,
          "attribute has already defined value in outerrole - A"
        )
      ) }

      it "force set" do
        expect(@outerrole.set_attr!("houcho::rspec::studio3104", { "A" => "anpanman" }))
      end

      it { expect { @outerrole.set_attr("invalid_role",{ A: "apple", B: "banana", C: "chocolate" }) }.to(
        raise_error(Houcho::OuterRoleExistenceException, "outer role does not exist - invalid_role") 
      ) }

      it { expect(@outerrole.del_attr("houcho::rspec::studio3104", "C")).to eq({ :C => "chocolate" }) }
      it { expect(@outerrole.get_attr("houcho::rspec::studio3104")).to eq({ A: "anpanman", B: "banana" }) }
      it { expect(@outerrole.del_attr("houcho::rspec::studio3104")).to eq({ A: "anpanman", B: "banana" }) }
      it { expect(@outerrole.get_attr("houcho::rspec::studio3104")).to eq({}) }
    end
  end


  describe Houcho::Spec::Runner do
    context "run role" do
      it do
        expect(@specrunner.execute_role("studio3104", [], true)).to eq([
          "TARGET_HOST=hostA parallel_rspec #{Houcho::Config::SPECDIR}/specA_spec.rb",
          "TARGET_HOST=test1.studio3104.com parallel_rspec #{Houcho::Config::SPECDIR}/specA_spec.rb",
          "TARGET_HOST=test2.studio3104.com parallel_rspec #{Houcho::Config::SPECDIR}/specA_spec.rb"
        ])
      end

      it "with exclude host" do
        expect(@specrunner.execute_role("studio3104", "test1.studio3104.com", true)).to eq([
          "TARGET_HOST=hostA parallel_rspec #{Houcho::Config::SPECDIR}/specA_spec.rb",
          "TARGET_HOST=test2.studio3104.com parallel_rspec #{Houcho::Config::SPECDIR}/specA_spec.rb"
        ])
      end
    end

    context "run manually" do
      it do
        expect(@specrunner.execute_manually(
          ["test3.studio3104.com", "test4.studio3104.com"],
          "specA",
          true
        )).to eq([
          "TARGET_HOST=test3.studio3104.com parallel_rspec #{Houcho::Config::SPECDIR}/specA_spec.rb",
          "TARGET_HOST=test4.studio3104.com parallel_rspec #{Houcho::Config::SPECDIR}/specA_spec.rb"
        ])
      end

      it "case of spec not exist" do
        expect { @specrunner.execute_manually("test5.studio3104.com", ["specA", "specX"], true) }.to(
          raise_error Houcho::SpecFileException, "No such spec file - specX"
        )
      end
    end

    context "check spec" do
      it { expect(@specrunner.check("specA", 2, true).size).to be(2) }

      it "case of spec not exist" do
        expect { @specrunner.check("specX", 2) }.to(
          raise_error Houcho::SpecFileException, "No such spec file - specX"
        )
      end
    end
  end
end
