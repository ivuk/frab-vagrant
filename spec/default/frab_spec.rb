require 'spec_helper'

describe user('rails') do
  it { should exist }
  it { should have_home_directory '/home/rails' }
  it { should have_login_shell '/usr/sbin/nologin' }
end

describe group('rails') do
  it { should exist }
end

describe file('/home/rails/frab-app') do
  it { should be_directory }
  it { should be_owned_by 'rails' }
  it { should be_grouped_into 'rails' }
end

describe package('bundler') do
  let(:path) { '/home/rails/.rbenv/shims' }
  it { should be_installed.by('gem') }
end

describe file('/home/rails/.bash_aliases') do
  it { should be_file }
end

describe file('/home/rails/frab-app/config/database.yml') do
  it { should be_file }
  it { should contain /production:/ }
  it { should contain /adapter: mysql2/ }
end

describe file('/home/rails/frab-app/config/settings.yml') do
  it { should be_file }
end

describe file('/home/rails/.rbenv/versions/1.9.3-p551/bin/ruby') do
  it { should be_executable }
end

describe command('su -l -s /bin/bash -c ". /home/rails/.bash_aliases; rbenv global" rails') do
  its(:stdout) { should match /1\.9\.3-p551/ }
end

describe file('/home/rails/frab-app/config/initializers/secret_token.rb') do
  it { should be_file }
  it { should_not contain /'iforgottochangetheexampletokenandnowvisitorscanexecutecodeonmyserver'/ }
  it { should contain /^Frab::Application.config.secret_token =/ }
end

describe command('curl http://localhost/en/session/new | grep "frab - Conference Management"') do
  its(:stdout) { should match /frab - Conference Management/ }
end
