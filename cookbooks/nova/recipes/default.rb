packages = %w{ openstack-keystone  openstack-glance openstack-nova openstack-nova-novncproxy python-paste-deploy dnsmasq-utils }

state_dir = node['nova']['state_dir']

network_config_path = '/etc/sysconfig/network-scripts/'

packages.each do |pkg|
  package pkg
end

nova_user= node['keystone']['nova_user']['username']
nova_passwd = node['keystone']['nova_user']['password']

ipaddress = node['ipaddress']

private_ipaddress = node['os_networks']['management'].split('.')[0..2].join('.')+'.'+node['id']
nova_ipaddress = node['nova']['fixed_range'].split('.')[0..2].join('.')+'.'+node['id']

if node['nodes_manage'] != ''
    control_node_ip = node['nodes_manage']
else
    control_node_ip = ipaddress
end

control_node_private_ip = node['os_networks']['management'].split('.')[0..2].join('.')+'.1'

db_ipaddress = node['os_networks']['management'].split('.')[0..2].join('.')+'.%'

rabbit_user =  node['rabbitmq']['username']
rabbit_passwd =  node['rabbitmq']['password']


db_user = node['nova']['db']['username']
db_passwd = node['nova']['db']['password']

virt_type = 'kvm'

if ipaddress == control_node_ip
  execute 'create_nova_database' do
    command "mysql -e 'create database nova;'"
    not_if "ls /var/lib/mysql /data/mysql/3306/data | grep nova"
    notifies :run, "execute[create_nova_user]", :immediately
  end

  create_keystone_use_sql = "grant all on  nova.*  to  %s@'%s' identified by
  '%s';" % [db_user,db_ipaddress,db_passwd]

  execute 'create_nova_user' do
    command 'mysql -e "%s"' % create_keystone_use_sql
    action :nothing
  end
end


directory "/var/lock/nova" do
  owner "nova"
  group "nova"
  mode "0700"
  action :create
end

directory state_dir do
  owner "nova"
  group "nova"
  mode "0751"
  action :create
  recursive true
end

execute 'state_dir_move' do
  command 'cp -pr /var/lib/nova/* %s' % state_dir
  not_if 'ls %s | grep instances' % state_dir
end

node['nova']['nova_interface'].each_pair do |k,v|
    template network_config_path+'ifcfg-'+v do
      source "net_interface.erb"
      mode '0400'
      variables(
          'inter_name' => v,
          'bridge_name' => k
      )
    end
 
    template network_config_path+'ifcfg-'+k do
      source 'bridge.erb'
      mode '0400'
      owner 'root'
      group 'root'
      variables(
        'name' => k,
        'ipaddress' => '',
        'netmask' =>  ''
      )
    notifies :run, "execute[restart_network]", :immediately
    end

end


execute "restart_network" do
    command "/etc/init.d/network restart"
    action :nothing
end



template '/etc/nova/nova.conf' do
  source "nova.conf.erb"
  mode '0644'
  owner 'nova'
  group 'nova'
  variables(
    'state_dir' => state_dir,
    'ipaddress' => ipaddress,
    'rabbit_user' => rabbit_user,
    'rabbit_pass' => rabbit_passwd,
    'rabbit_ipaddress' => control_node_private_ip,
    'scheduler_driver' => node['nova']['scheduler_driver'],
    'network_manager' => node['nova']['network_manager'],
    'public_interface' => node['nova']['manage_interface'],
    'flat_injected' => node['nova']['flat_injected'],
    'libvirt_inject_password' => node['nova']['libvirt_inject_password'],
    'fixed_range' => node['nova']['fixed_range'],
    'virt_type' => virt_type,
    'glance_api_ipaddress' => control_node_ip,
    'glance_api_port' => 9292,
    'rabbit_durable' => node['nova']['rabbit_durable'],
    'user' => db_user,
    'passwd' => db_passwd,
    'db_ipaddress' => control_node_private_ip,
    'db_name' => 'nova',
    "vncserver_listen" => private_ipaddress,
    "vncserver_proxyclient_address" => control_node_private_ip,
    "control_node_ip" => control_node_ip,
    "flat_interface" => node["nova"]["flat_interface"],
    "flat_injected" => node["nova"]["flat_injected"],
    "fixed_range" => node["nova"]["fixed_range"],
    "allow_same_net_traffic" => node["nova"]["allow_same_net_traffic"],
    "cpu_allocation_ratio" => node["nova"]["cpu_allocation_ratio"],
    "ram_allocation_ratio" => node["nova"]["ram_allocation_ratio"]
  )
end

template '/etc/nova/api-paste.ini' do
  source 'api-paste.ini.erb'
  mode '0400'
  owner 'nova'
  group 'nova'
  variables(
    "control_node_ip" => control_node_ip,
    'tenant_name' => 'service',
    'user_name' => nova_user,
    'user_passwd' => nova_passwd
  )
end

service "openstack-nova-network" do
    action [:enable,:start]
end


service "openstack-nova-compute" do
    action [:enable,:start]
end

if ipaddress == control_node_ip

    execute 'nova_db_sync' do
      command 'nova-manage db sync'
    end

    execute 'nova_db_sync' do
      command "nova-manage network create --label=private --fixed_range_v4=#{node['nova']['fixed_range']} --network_size=65535 --bridge=private --bridge_interface=private --multi_host=T"
      not_if "nova-manage network list"
    end

    service "openstack-nova-api" do
        action [:enable,:start]
    end
    service "openstack-nova-scheduler" do
        action [:enable,:start]
    end

    service "openstack-nova-consoleauth" do
        action [:enable,:start]
    end

    service "openstack-nova-novncproxy" do
        action [:enable,:start]
    end
end
