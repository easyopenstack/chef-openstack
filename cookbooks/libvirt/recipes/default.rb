package "libvirt" do
  action :install
end

package "avahi" do
  action :install
end

execute 'qemu-kvm' do
  command 'ln -s /usr/libexec/qemu-kvm /usr/bin/qemu-system-x86_64'
  not_if 'ls /usr/bin | grep qemu-system-x86_64'
end


template "/etc/libvirt/qemu/networks/default.xml" do
    source "default.xml.erb"
    mode "0644"
end

execute "delete_virbr0" do
    command "ifconfig virbr0 down && brctl delbr virbr0 && kill -9 `ps aux | grep dnsmasq | grep 122.1 | awk '{print $2}'`"
    only_if "ifconfig virbr0"
end

service 'messagebus' do
    action [:start,:enable]
end

service 'avahi-daemon' do
    action [:start,:enable]
end

service 'libvirtd' do
    action [:start,:enable]
end

