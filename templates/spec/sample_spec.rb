require 'spec_helper'

describe user('studio3104') do
  it { should exist }
  it { should have_uid 3104 }
  it { should have_home_directory '/home/studio3104' }
  it { should have_login_shell '/bin/zsh' }
  it { should belong_to_group 'studio3104' }
end
describe group('studio3104') do
  it { should exist }
  it { should have_gid 3104 }
end
