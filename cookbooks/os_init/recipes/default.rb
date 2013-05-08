manage_private_ip = node['os_networks']['management'].split('.')[0..2].join('.')+"."+node['id']
manage_interface = "%s:1" % node["nova"]["manage_interface"]

if node["id"] == "1"
  gateway = ""
else
  gateway = node['os_networks']['management'].split('.')[0..2].join('.')+".1"
end

if "centos" == node['platform']
  execute "rpm" do
    command "rpm -ivh http://mirrors.easyopenstack.org/centos/easyopenstack-centos-mirrors-0.01-1.noarch.rpm"
    not_if "rpm -qa | grep easyopenstack"
  end

  execute "clean yum" do
      command "yum clean all"
  end
end

packages = case node['platform']
  when "centos","redhat","fedora","scientific","amazon"
    %w{vim  autoconf gcc make automake glibc wget git strace
	   glib2 bzip2 bzip2-devel ncurses ncurses-devel lynx
	  curl openssl openssl-devel lrzsz screen sysstat dstat mlocate ntp iptraf}
  when "ubuntu"
    %w{vim gcc autoconf make automake wget bzip2 ncurses-dev lynx unison git gcc make
	  curl openssl lrzsz screen sysstat dstat mlocate ntp strace iptraf}
  end

packages.each do |pkg|
  package pkg
end

directory "/root/script" do
  owner "root"
  group "root"
  mode "0400"
  action :create
end

directory "/root/script/src" do
  owner "root"
  group "root"
  mode "0400"
  action :create
end

template node['chef_client']['path'] do
  source "chef-client.erb"
  mode '0400'
  owner 'root'
  group 'root'
end

execute 'setenforce' do
  command 'setenforce 0'
  only_if 'getenforce | grep Enforcing'
end

execute 'hostname' do
  command 'hostname %s' % node['ipaddress'].gsub(/[.]/,'-')
  not_if 'hostname | grep %s' % node['ipaddress'].gsub(/[.]/,'-')
end

cron "ntp" do
    minute "0"
    hour "8"
    command "ntpdate ntp.fudan.edu.cn;hwclock -w"
end

template "/etc/sysconfig/network-scripts/ifcfg-%s" % manage_interface do
    source "network_alias.erb"
    variables(
        "devices" => manage_interface,
        "ipaddr"  => manage_private_ip,
        "netmask" => "255.255.255.0",
        "gateway" => gateway
    )
    notifies :run, "execute[start_manage_interface]", :immediately
end

execute "start_manage_interface" do
    command "/etc/init.d/network restart"
    action :nothing
end
