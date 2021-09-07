require "spec_helper"
require "serverspec"

package = "vault"
service = "vault"
config  = "/etc/vault.hcl"
user    = "vault"
group   = "vault"
ports   = [8200]

case os[:family]
when "freebsd"
  config = "/usr/local/etc/vault.hcl"
  db_dir = "/var/db/vault"
end

describe package(package) do
  it { should be_installed }
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
