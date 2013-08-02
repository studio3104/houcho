$LOAD_PATH.unshift "/Users/JP11546/Documents/houcho/lib"

require "tmpdir"
spectmp = Dir.mktmpdir("houcho")
ENV["HOUCHO_ROOT"] = spectmp

require "rspec"
require "houcho"
require "houcho/role"
require "houcho/host"
require "houcho/element"
require "tempfile"
require "fileutils"

describe Houcho do
  before :all do
    @role = Houcho::Role.new
    @host = Houcho::Host.new

    @role.create(["studio3104", "studio3105"])
    @host.attach("hostA", "studio3104")

#    File.write("spec/specA_spec.rb"," ")
#    Houcho::Spec.attach("specA", "studio3104")
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


=begin
    context "get details of a role" do
      it do
        expect(Houcho::Role.details(["studio3104"])).to eq(
          {
            "studio3104" => {
              "host" => [ "hostA" ],
              "spec" => [ "specA" ],
              "cf"   => { "houcho::rspec::studio3104" => { "host" => [ "test1.studio3104.com", "test2.studio3104.com", ] } }
            }
          }
        )
      end
    end

    it { expect(Houcho::Role.index("studio3104")).to be(1)}
    it { expect(Houcho::Role.indexes_regexp(/studio310\d/)).to eq([1,2])}
    it { expect(Houcho::Role.name(1)).to eq("studio3104")}
=end
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

=begin
    context "get details of a host" do
      it "host from original defined" do
        expect(@host.details(["hostA"])).to eq(
          { "hostA" => { "role" => [ "studio3104" ] } }
        )
      end

      it "host from cf defined" do
        expect(Houcho::Host.details(["test1.studio3104.com"])).to eq(
          { "test1.studio3104.com" => { "cf" => [ "houcho::rspec::studio3104" ] } }
        )
      end

      it "both" do
        expect(Houcho::Host.details(["hostA", "test1.studio3104.com"])).to eq(
          {
            "hostA"                => { "role" => [ "studio3104" ] },
            "test1.studio3104.com" => { "cf"   => [ "houcho::rspec::studio3104" ] },
          }
        )
      end

      context "get host list attached or defined cf" do
        it "all of hosts" do
          expect(Houcho::Host.elements).to eq(["hostA"])
        end

        it "hosts of one of role" do
          expect(Houcho::Host.elements(1)).to eq(["hostA"])
        end
      end
    end
=end
  end


  after :all do
    FileUtils.rm_rf(spectmp)
  end
end


__END__
  describe Houcho::Spec do

  end


  describe Houcho::Spec::Runner do
    context "run role" do
      it do
        expect(Houcho::Spec::Runner.exec(["studio3104"],[],[],[],{},true)).to eq([
          "TARGET_HOST=hostA parallel_rspec spec/specA_spec.rb",
          "TARGET_HOST=test1.studio3104.com parallel_rspec spec/specA_spec.rb",
          "TARGET_HOST=test2.studio3104.com parallel_rspec spec/specA_spec.rb"
        ])
      end

      it "with exclude host" do
        expect(Houcho::Spec::Runner.exec(["studio3104"],["test1.studio3104.com"],[],[],{},true)).to eq([
          "TARGET_HOST=hostA parallel_rspec spec/specA_spec.rb",
          "TARGET_HOST=test2.studio3104.com parallel_rspec spec/specA_spec.rb"
        ])
      end
    end

    context "run manually" do
      it do
        expect(Houcho::Spec::Runner.exec([],[],["test3.studio3104.com", "test4.studio3104.com"],["specA"],{},true)).to eq([
          "TARGET_HOST=test3.studio3104.com parallel_rspec spec/specA_spec.rb",
          "TARGET_HOST=test4.studio3104.com parallel_rspec spec/specA_spec.rb"
        ])
      end

      it "case of spec not exist" do
        expect { Houcho::Spec::Runner.exec([],[],["test5.studio3104.com"],["specA", "specX"],{},true) }.to raise_error
      end
    end

    context "check spec" do
      it { expect(Houcho::Spec::Runner.check(["specA"], 2, true).size).to be(2) }
      it "case of spec not exist" do
        expect { Houcho::Spec::Runner.check(["specX"], 2, true) }.to raise_error
      end
    end
  end


end
