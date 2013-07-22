require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

spectmp = Dir.mktmpdir('spec')
include Houcho

describe Houcho do
  before :all do
    Dir.chdir(spectmp)
    init_repo
    Role.create(['studio3104', 'studio3105'])
    Host.attach(['hostA'], ['studio3104'])

    File.write('spec/specA_spec.rb',' ')
    Spec.attach(['specA'], ['studio3104'])

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
    CloudForecast.load_yaml
    CloudForecast::Role.attach(['houcho::rspec::studio3104'], ['studio3104'])
  end


  describe Role do
    context 'create and delete a role' do
      it { Role.create(['www']) }
      it { expect { Role.create(['www']) }.to raise_error }
      it { Role.delete(['www']) }
      it { expect { Role.delete(['web']) }.to raise_error }
    end

    context 'create and delete two roles' do
      it { Role.create(['studio3104::www', 'studio3104::database']) }
      it { expect { Role.create(['studio3104::www', 'studio3104::database']) }.to raise_error }
      it { Role.delete(['studio3104::www', 'studio3104::database']) }
      it { expect { Role.delete(['studio3104::www', 'studio3104::database']) }.to raise_error }
    end

    context 'rename a role' do
      it { Role.rename('studio3105', 'studio3106') }
      it { expect { Role.rename('invalid_role', 'studio3106') }.to raise_error }
      it { expect { Role.rename('studio3106', 'studio3104') }.to raise_error }
      it { Role.rename('studio3106', 'studio3105') }
    end

    context 'get all roles' do
      it { Role.all.should eq ['studio3104', 'studio3105'] }
    end

    context 'get details of a role' do
      it do
        expect(Role.details(['studio3104'])).to eq(
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

    it { expect(Role.index('studio3104')).to be(1)}
    it { expect(Role.indexes_regexp(/studio310\d/)).to eq([1,2])}
    it { expect(Role.name(1)).to eq('studio3104')}
  end


  describe Houcho::Host do
    context 'attach and detach hosts to roles' do
      it { Host.attach(['host1', 'host2'], ['studio3104', 'studio3105']) }
      it { expect { Host.attach(['host1'], ['invalid_role']) }.to raise_error }
      it { Host.detach(['host1', 'host2'], ['studio3104', 'studio3105']) }
      it { expect { Host.detach(['host1'], ['invalid_role']) }.to raise_error }
    end

    context 'get details of a host' do
      it 'host from original defined' do
        expect(Host.details(['hostA'])).to eq(
          { 'hostA' => { 'role' => [ 'studio3104' ] } }
        )
      end

      it 'host from cf defined' do
        expect(Host.details(['test1.studio3104.com'])).to eq(
          { 'test1.studio3104.com' => { 'cf' => [ 'houcho::rspec::studio3104' ] } }
        )
      end

      it 'both' do
        expect(Host.details(['hostA', 'test1.studio3104.com'])).to eq(
          {
            'hostA'                => { 'role' => [ 'studio3104' ] },
            'test1.studio3104.com' => { 'cf'   => [ 'houcho::rspec::studio3104' ] },
          }
        )
      end

      context 'get host list attached or defined cf' do
        it 'all of hosts' do
          expect(Host.elements).to eq(["hostA"])
        end

        it 'hosts of one of role' do
          expect(Host.elements(1)).to eq(["hostA"])
        end
      end
    end
  end


  describe Houcho::Spec::Runner do
    context 'run role' do
      it do
        expect(Spec::Runner.exec(['studio3104'],[],[],[],{},true)).to eq([
          'TARGET_HOST=hostA parallel_rspec spec/specA_spec.rb',
          'TARGET_HOST=test1.studio3104.com parallel_rspec spec/specA_spec.rb',
          'TARGET_HOST=test2.studio3104.com parallel_rspec spec/specA_spec.rb'
        ])
      end

      it 'with exclude host' do
        expect(Spec::Runner.exec(['studio3104'],['test1.studio3104.com'],[],[],{},true)).to eq([
          'TARGET_HOST=hostA parallel_rspec spec/specA_spec.rb',
          'TARGET_HOST=test2.studio3104.com parallel_rspec spec/specA_spec.rb'
        ])
      end
    end

    context 'run manually' do
      it do
        expect(Spec::Runner.exec([],[],['test3.studio3104.com', 'test4.studio3104.com'],['specA'],{},true)).to eq([
          'TARGET_HOST=test3.studio3104.com parallel_rspec spec/specA_spec.rb',
          'TARGET_HOST=test4.studio3104.com parallel_rspec spec/specA_spec.rb'
        ])
      end

      it 'case of spec not exist' do
        expect { Spec::Runner.exec([],[],['test5.studio3104.com'],['specA', 'specX'],{},true) }.to raise_error
      end
    end

    context 'check spec' do
      it { expect(Spec::Runner.check(['specA'], 2, true).size).to be(2) }
      it 'case of spec not exist' do
        expect { Spec::Runner.check(['specX'], 2, true) }.to raise_error
      end
    end
  end


  after :all do
    Dir.chdir('/')
    FileUtils.rm_rf(spectmp)
  end
end
