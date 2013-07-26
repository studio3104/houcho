#require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
$LOAD_PATH.unshift '/Users/JP11546/Documents/houcho/lib'

require 'rspec'
require 'houcho'
require 'houcho/repository'
require 'houcho/role'
require 'houcho/host'
require 'houcho/spec'
require 'houcho/spec/runner'
require 'houcho/yamlhandle'
require 'houcho/element'
require 'houcho/cloudforecast'
require 'houcho/cloudforecast/role'
require 'houcho/cloudforecast/host'
require 'houcho/ci'
require 'tmpdir'
require 'tempfile'
require 'fileutils'

spectmp = Dir.mktmpdir('spec')

describe Houcho do
  before :all do
    Dir.chdir(spectmp)
    Houcho::Repository.init
    Houcho::Role.create(['studio3104', 'studio3105'])
    Houcho::Host.attach('hostA', 'studio3104')

    File.write('spec/specA_spec.rb',' ')
    Houcho::Spec.attach('specA', 'studio3104')

    File.write('./role/cloudforecast/cf.yaml', <<EOD
--- #houcho
servers:
  - label: rspec
    config: studio3104
    hosts:
      - test1.studio3104.com
      - test2.studio3104.com
EOD
    )
    Houcho::CloudForecast.load
    Houcho::CloudForecast::Role.attach('houcho::rspec::studio3104', 'studio3104')
  end


  describe Houcho::Role do
    context 'create and delete a role' do
      it { Houcho::Role.create('www') }
      it { expect { Houcho::Role.create('www') }.to raise_error }
      it { Houcho::Role.delete('www') }
      it { expect { Houcho::Role.delete('web') }.to raise_error }
    end

    context 'create and delete two roles' do
      it { Houcho::Role.create(['studio3104::www', 'studio3104::database']) }
      it { expect { Houcho::Role.create(['studio3104::www', 'studio3104::database']) }.to raise_error }
      it { Houcho::Role.delete(['studio3104::www', 'studio3104::database']) }
      it { expect { Houcho::Role.delete(['studio3104::www', 'studio3104::database']) }.to raise_error }
    end

    context 'rename a role' do
      it { Houcho::Role.rename('studio3105', 'studio3106') }
      it { expect { Houcho::Role.rename('invalid_role', 'studio3106') }.to raise_error }
      it { expect { Houcho::Role.rename('studio3106', 'studio3104') }.to raise_error }
      it { Houcho::Role.rename('studio3106', 'studio3105') }
    end

    context 'get all roles' do
      it { expect(Houcho::Role.all).to eq(['studio3104', 'studio3105']) }
    end

    context 'get details of a role' do
      it do
        expect(Houcho::Role.details(['studio3104'])).to eq(
          {
            'studio3104' => {
              'host' => [ 'hostA' ],
              'spec' => [ 'specA' ],
              'cf'   => { 'houcho::rspec::studio3104' => { 'host' => [ 'test1.studio3104.com', 'test2.studio3104.com', ] } }
            }
          }
        )
      end
    end

    it { expect(Houcho::Role.index('studio3104')).to be(1)}
    it { expect(Houcho::Role.indexes_regexp(/studio310\d/)).to eq([1,2])}
    it { expect(Houcho::Role.name(1)).to eq('studio3104')}
  end


  describe Houcho::Host do
    context 'attach and detach hosts to roles' do
      it { Houcho::Host.attach(['host1', 'host2'], ['studio3104', 'studio3105']) }
      it { expect { Houcho::Host.attach('host1', 'invalid_role') }.to raise_error }
      it { Houcho::Host.detach(['host1', 'host2'], ['studio3104', 'studio3105']) }
      it { expect { Houcho::Host.detach('host1', 'invalid_role') }.to raise_error }
    end

    context 'get details of a host' do
      it 'host from original defined' do
        expect(Houcho::Host.details(['hostA'])).to eq(
          { 'hostA' => { 'role' => [ 'studio3104' ] } }
        )
      end

      it 'host from cf defined' do
        expect(Houcho::Host.details(['test1.studio3104.com'])).to eq(
          { 'test1.studio3104.com' => { 'cf' => [ 'houcho::rspec::studio3104' ] } }
        )
      end

      it 'both' do
        expect(Houcho::Host.details(['hostA', 'test1.studio3104.com'])).to eq(
          {
            'hostA'                => { 'role' => [ 'studio3104' ] },
            'test1.studio3104.com' => { 'cf'   => [ 'houcho::rspec::studio3104' ] },
          }
        )
      end

      context 'get host list attached or defined cf' do
        it 'all of hosts' do
          expect(Houcho::Host.elements).to eq(["hostA"])
        end

        it 'hosts of one of role' do
          expect(Houcho::Host.elements(1)).to eq(["hostA"])
        end
      end
    end
  end


  describe Houcho::Spec do

  end


  describe Houcho::Spec::Runner do
    context 'run role' do
      it do
        expect(Houcho::Spec::Runner.exec(['studio3104'],[],[],[],{},true)).to eq([
          'TARGET_HOST=hostA parallel_rspec spec/specA_spec.rb',
          'TARGET_HOST=test1.studio3104.com parallel_rspec spec/specA_spec.rb',
          'TARGET_HOST=test2.studio3104.com parallel_rspec spec/specA_spec.rb'
        ])
      end

      it 'with exclude host' do
        expect(Houcho::Spec::Runner.exec(['studio3104'],['test1.studio3104.com'],[],[],{},true)).to eq([
          'TARGET_HOST=hostA parallel_rspec spec/specA_spec.rb',
          'TARGET_HOST=test2.studio3104.com parallel_rspec spec/specA_spec.rb'
        ])
      end
    end

    context 'run manually' do
      it do
        expect(Houcho::Spec::Runner.exec([],[],['test3.studio3104.com', 'test4.studio3104.com'],['specA'],{},true)).to eq([
          'TARGET_HOST=test3.studio3104.com parallel_rspec spec/specA_spec.rb',
          'TARGET_HOST=test4.studio3104.com parallel_rspec spec/specA_spec.rb'
        ])
      end

      it 'case of spec not exist' do
        expect { Houcho::Spec::Runner.exec([],[],['test5.studio3104.com'],['specA', 'specX'],{},true) }.to raise_error
      end
    end

    context 'check spec' do
      it { expect(Houcho::Spec::Runner.check(['specA'], 2, true).size).to be(2) }
      it 'case of spec not exist' do
        expect { Houcho::Spec::Runner.check(['specX'], 2, true) }.to raise_error
      end
    end
  end


  after :all do
    Dir.chdir('/')
    FileUtils.rm_rf(spectmp)
  end
end
