require 'spec_helper'

describe 'role_ggonda_cassandra' do
  context 'on an unsupported operating system' do
    let(:facts) do
      {
        :osfamily        => 'Solaris',
        :operatingsystem => 'Nexenta',
      }
    end

    it { is_expected.to compile.and_raise_error(/unsupported operatingsystem/i) }
  end

  context 'on a supported operating system' do
    let(:facts) do
      {
        :osfamily               => 'RedHat',
        :operatingsystem        => 'CentOS',
        :operatingsystemrelease => '7',
        :kernel                 => 'Linux',
        :ipaddress              => '192.168.1.100',
        :hostname               => 'testnode',
        :fqdn                   => 'testnode.example.com'
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('role_ggonda_cassandra') }
    it { is_expected.to contain_class('profile_ggonda_cassandr') }
  end
end
