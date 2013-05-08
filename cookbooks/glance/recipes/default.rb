packages = %w{ openstack-keystone  openstack-glance python-paste-deploy }

packages.each do |pkg|
  package pkg
end

glance_user= node['keystone']['glance_user']['username']
glance_passwd = node['keystone']['glance_user']['password']
ipaddress = node['ipaddress']
private_ipaddress = node['os_networks']['management'].split('.')[0..2].join('.')+'.'+node['id']

if node['nodes_manage'] != ''
    control_node_ip = node['nodes_manage']
else
    control_node_ip = ipaddress
end

control_node_private_ip = node['os_networks']['management'].split('.')[0..2].join('.')+'.1'

db_ipaddress = node['os_networks']['management'].split('.')[0..2].join('.')+'.%'

rabbit_user =  node['rabbitmq']['username']
rabbit_passwd =  node['rabbitmq']['password']


db_user = node['glance']['db']['username']
db_passwd = node['glance']['db']['password']


execute 'create_glance_database' do
  command "mysql -e 'create database glance;'"
  not_if "ls /var/lib/mysql /data/mysql/3306/data | grep glance"
  notifies :run, "execute[create_glance_user]", :immediately
end

create_keystone_use_sql = "grant all on  glance.*  to  %s@'%s' identified by
'%s';" % [db_user,db_ipaddress,db_passwd]

execute 'create_glance_user' do
  command 'mysql -e "%s"' % create_keystone_use_sql
  action :nothing
end




template '/etc/glance/glance-api.conf' do
  source 'glance-api.conf.erb'
  mode '0400'
  owner 'glance'
  group 'glance'
  variables(
    'ipaddress' => ipaddress,
    'private_ipaddress' => private_ipaddress,
    'control_node_private_ip' => control_node_private_ip,
    'rabbit_user' => rabbit_user,
    'rabbit_passwd' => rabbit_passwd
  )
end

template '/etc/glance/glance-registry.conf' do
  source 'glance-registry.conf.erb'
  mode '0400'
  owner 'glance'
  group 'glance'
  variables(
    'private_ipaddress' => private_ipaddress,
    'db_user' => db_user,
    'db_passwd' => db_passwd,
    'control_node_private_ip' => control_node_private_ip
  )
end

execute 'registry_start' do
  command '/etc/init.d/openstack-glance-registry start'
  not_if 'netstat  -ln | grep 9191'
end


template '/etc/glance/glance-api-paste.ini' do
  source 'glance-api-paste.ini.erb'
  mode '0400'
  owner 'glance'
  group 'glance'
  variables(
    'control_node_ip' => control_node_ip,
    'glance_user' => glance_user,
    'glance_passwd' => glance_passwd
  )
end

template '/etc/glance/glance-registry-paste.ini' do
  source 'glance-registry-paste.ini.erb'
  mode '0400'
  owner 'glance'
  group 'glance'
  variables(
    'control_node_ip' => control_node_ip,
    'glance_user' => glance_user,
    'glance_passwd' => glance_passwd
  )
end

service "openstack-glance-api" do
    action [:enable,:start]
end


service "openstack-glance-registry" do
    action [:enable,:start]
end
