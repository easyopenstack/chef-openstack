openstack_version = node['openstack_patch']['openstack_version']


repo_file = "http://mirrors.easyopenstack.org/openstack/openstack-essex/epel-openstack-%s.repo" % openstack_version

remote_file "/etc/yum.repos.d/epel-openstack-%s.repo" % openstack_version do
    source repo_file
    mode "0644"
end

execute "delete_iptables_rules" do
    command "echo '' > /etc/sysconfig/iptables"
    only_if "grep -w 'system-config-firewall' /etc/sysconfig/iptables"
    notifies :run, "execute[restart_iptables]", :immediately
end

execute "restart_iptables" do
    command "/etc/init.d/iptables restart"
    action :nothing
end
