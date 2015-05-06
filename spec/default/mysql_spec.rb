require 'spec_helper'

describe package('mysql-server') do
  it { should be_installed }
end

describe package('mysql-server-5.5') do
  it { should be_installed }
end

describe service('mysql') do
  it { should be_enabled }
  it { should be_running }
end

describe port(3306) do
  it { should be_listening }
end

describe file('/etc/mysql/my.cnf') do
  it { should be_file }
  it { should contain /bind-address		= 127.0.0.1/ }
end
