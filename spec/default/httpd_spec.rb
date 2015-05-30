require 'spec_helper'

describe package('apache2') do
  it { should be_installed }
end

describe service('apache2') do
  it { should be_enabled }
  it { should be_running }
end

describe port(80) do
  it { should be_listening }
end

describe command('apachectl -M') do
  its(:stdout) { should match /passenger_module/ }
  its(:exit_status) { should eq 0 }
end

describe file('/etc/apache2/sites-available/000-default.conf') do
  it { should be_file }
end

describe file('/etc/apache2/sites-enabled/000-default.conf') do
  it { should_not be_linked_to '../sites-available/000-default.conf' }
  it { should_not be_file }
end

describe file('/etc/apache2/sites-enabled/001-frab.conf') do
  it { should be_linked_to '../sites-available/001-frab.conf' }
  it { should contain /ServerName localhost.localdomain/ }
end

describe file('/etc/apache2/mods-available/passenger.conf') do
  it { should be_file }
  it { should contain /PassengerDefaultRuby \/home\/rails\/\.rbenv\/versions\/1\.9\.3\-p551\/bin\/ruby/ }
end

describe file('/etc/apache2/mods-enabled/passenger.conf') do
  it { should be_linked_to '../mods-available/passenger.conf' }
end
