require 'tmpdir'
require 'tempfile'
require 'Conductor'

def capture(stream)
  begin
    stream = stream.to_s
    eval "$#{stream} = StringIO.new"
    yield
    result = eval("$#{stream}").string
  ensure
    eval("$#{stream} = #{stream.upcase}")
  end

  result
end

describe Conductor do
  before :all do
    spectmp = Dir.mktmpdir('spec')
    Dir.chdir spectmp
    subject.initialize_houcho
    File.write('role/spec.yaml',<<EOH
servers:
  - label: www
    config: apache.yaml
    hosts:
      - 192.168.1.100 apache101.studio3104.test
      - 192.168.1.101 apache102.studio3104.test
  - label: db
    config: mysql.yaml
    hosts:
      - 192.168.1.200 mysql101.studio3104.test
      - 192.168.1.201 mysql102.studio3104.test
EOH
    )
    subject.mk_spec_directory
    File.write('spec/www/test_spec.rb', "require 'spec_helper'")
    File.write('spec/apache/test_spec.rb', "require 'spec_helper'")
    File.write('spec/db/test_spec.rb', "require 'spec_helper'")
    File.write('spec/mysql/test_spec.rb', "require 'spec_helper'")
  end

  it 'houcho show hostlist --all' do
    expect(capture(:stdout) {
      subject.all_host_list
    }).to eq <<-EOH.gsub(/^\s+/, '')
      apache101.studio3104.test
      apache102.studio3104.test
      mysql101.studio3104.test
      mysql102.studio3104.test
    EOH
  end

  it 'houcho show hostlist -R ROLENAME' do
    expect(capture(:stdout) {
      subject.host_list_by_role('www')
    }).to eq <<-EOH.gsub(/^\s+/, '') + "\n"
      [www]
      apache101.studio3104.test
      apache102.studio3104.test
    EOH
  end

  it 'houcho show rolelist --all' do
    expect(capture(:stdout) {
      subject.all_role_list
    }).to eq "www\napache\ndb\nmysql\nserverspec_commons\n"
  end

  it 'houcho show rolelist -H HOSTNAME' do
    expect(capture(:stdout) {
      subject.role_list_by_host('apache101.studio3104.test')
    }).to eq <<-EOH.gsub(/^\s+/, '') + "\n"
      [apache101.studio3104.test]
      www
      apache
      serverspec_commons
    EOH
  end

  it 'houcho show speclist --all' do
    expect(capture(:stdout) {
      subject.all_spec_list
    }).to eq "test\n"
  end

  it 'houcho show speclist -R ROLENAME' do
    expect(capture(:stdout) {
      subject.spec_list_by_role('www')
    }).to eq "test\n"
  end

  it 'houcho runspec --all --dry-run' do
    expect(capture(:stdout) {
      subject.runspec_to_all_host({ukigumo: nil, ikachan: nil}, true)
    }).to eq <<-EOH.gsub(/^\s+/, '')
      TARGET_HOST=apache101.studio3104.test rspec spec/www/*_spec.rb
      TARGET_HOST=apache101.studio3104.test rspec spec/apache/*_spec.rb
      TARGET_HOST=apache102.studio3104.test rspec spec/www/*_spec.rb
      TARGET_HOST=apache102.studio3104.test rspec spec/apache/*_spec.rb
      TARGET_HOST=mysql101.studio3104.test rspec spec/db/*_spec.rb
      TARGET_HOST=mysql101.studio3104.test rspec spec/mysql/*_spec.rb
      TARGET_HOST=mysql102.studio3104.test rspec spec/db/*_spec.rb
      TARGET_HOST=mysql102.studio3104.test rspec spec/mysql/*_spec.rb
    EOH
  end

  it 'houcho runspec -H HOSTNAME -R ROLENAME--dry-run' do
    expect(capture(:stdout) {
      subject.runspec_to_host_by_role('apache101.studio3104.test', 'www', {ukigumo: nil, ikachan: nil}, true)
    }).to eq <<-EOH.gsub(/^\s+/, '')
      TARGET_HOST=apache101.studio3104.test rspec spec/www/*_spec.rb
    EOH
  end

  it 'houcho runspec -H HOSTNAME --dry-run' do
    expect(capture(:stdout) {
      subject.runspec_to_host('apache101.studio3104.test', {ukigumo: nil, ikachan: nil}, true)
    }).to eq <<-EOH.gsub(/^\s+/, '')
      TARGET_HOST=apache101.studio3104.test rspec spec/www/*_spec.rb
      TARGET_HOST=apache101.studio3104.test rspec spec/apache/*_spec.rb
    EOH
  end

  it 'houcho runspec -R ROLENAME --dry-run' do
    expect(capture(:stdout) {
      subject.runspec_by_role('www', {ukigumo: nil, ikachan: nil}, true)
    }).to eq <<-EOH.gsub(/^\s+/, '')
      TARGET_HOST=apache101.studio3104.test rspec spec/www/*_spec.rb
      TARGET_HOST=apache102.studio3104.test rspec spec/www/*_spec.rb
    EOH
  end

  after :all do
    # テンポラリディレクトリを消すのを入れる
    # rm_rfを使うとエラってダメだった
  end

end
