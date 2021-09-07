require "spec_helper"
require "serverspec"

package = "vault"
service = "vault"
config  = "/etc/vault.hcl"
user    = "vault"
group   = "vault"
ports   = [8200]
extra_packages = []
root_dir = ""
root_subdirs = []
mlock_limit = "2048M"

case os[:family]
when "freebsd"
  config = "/usr/local/etc/vault.hcl"
  extra_packages = %w{ textproc/jq }
  root_dir = "/usr/local/vault"
  root_subdirs = %w{ data }
end

describe file(root_dir) do
  it { should exist }
  it { should be_directory }
  it { should be_mode 755 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
end

root_subdirs.each do |d|
  describe file("#{root_dir}/#{d}") do
    it { should exist }
    it { should be_mode 755 }
    it { should be_owned_by user }
    it { should be_grouped_into group }
  end
end
describe package(package) do
  it { should be_installed }
end

extra_packages.each do |p|
  describe package(p) do
    it { should be_installed }
  end
end

describe file(config) do
  it { should be_file }
  its(:content) { should match Regexp.escape("Managed by ansible") }
end

case os[:family]
when "freebsd"
  describe file("/etc/rc.conf.d/vault") do
    it { should be_file }
    its(:content) { should match Regexp.escape("Managed by ansible") }
    its(:content) { should match Regexp.escape("vault_limits_mlock=\"#{mlock_limit}\"") }
  end
end

describe service(service) do
  it { should be_running }
  it { should be_enabled }
end

ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end

command "env VAULT_ADDR=http://127.0.0.1:8200 vault status" do
  its(:stderr) { should eq "" }
  its(:stdout) { should match(/^Version\s+/) }
  its(:exit_status) { should eq 0 }
end

command "env VAULT_ADDR=http://127.0.0.1:8200 vault operator init" do
  its(:stderr) { should eq "" }
  its(:exit_status) { should eq 0 }
end

describe file("#{root_dir}/.vault_init.yml") do
  it { should exist }
  it { should be_file }
  it { should be_owned_by user }
  it { should be_grouped_into group }
  it { should be_mode 600 }
  its(:content) { should match Regexp.escape("Created by ansible") }
end
