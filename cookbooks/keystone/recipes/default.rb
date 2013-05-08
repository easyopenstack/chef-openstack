packages = %w{ openstack-keystone python-novaclient python-paste-deploy }

packages.each do |pkg|
  package pkg
end

admin_token = node['keystone']['admin_token']
db_user = node['keystone']['db']['username']
db_passwd = node['keystone']['db']['password']
admin_user = node['keystone']['admin_user']['username']
admin_passwd = node['keystone']['admin_user']['password']
glance_user= node['keystone']['glance_user']['username']
glance_passwd = node['keystone']['glance_user']['password']
nova_user = node['keystone']['nova_user']['username']
nova_passwd = node['keystone']['nova_user']['password']
db_ipaddress = node['os_networks']['management'].split('.')[0..2].join('.')+'.%'
ipaddress = node['ipaddress']
control_node_ip = node['os_networks']['management'].split('.')[0..2].join('.')+'.1'

execute 'create_keystone_database' do
  command "mysql -e 'create database keystone;'"
  not_if "ls /data/mysql/3306/data/ /var/lib/mysql | grep keystone"
  notifies :run, "execute[create_keystone_user]", :immediately
end

create_keystone_use_sql = "grant all on  keystone.*  to  %s@'%s' identified by '%s';" % [db_user,db_ipaddress,db_passwd]

execute 'create_keystone_user' do
  command 'mysql -e "%s"' % create_keystone_use_sql
  action :nothing
end

template "/etc/keystone/keystone.conf" do
  source "keystone.conf.erb"
  mode "0400"
  owner "keystone"
  group "keystone"
  variables(
    'ipaddress' => ipaddress,
    'admin_token' => admin_token,
    'db_user' => db_user,
    'db_passwd' => db_passwd,
    'control_node' => control_node_ip
  )
end

template "/etc/keystone/default_catalog.templates" do
  source "default_catalog.templates.erb"
  mode "0400"
  owner "keystone"
  group "keystone"
  variables(
    'ipaddress' => ipaddress,
    'regions' => node['keystone']['regions']
  )
  notifies :run, "execute[keystone_restart]", :immediately
end

execute 'keystone_restart' do
  command '/etc/init.d/openstack-keystone restart'
  action :nothing
end

template "/root/.novarc" do
  source "novarc.erb"
  mode "0700"
  owner "root"
  group "root"
  variables(
    'ipaddress' => ipaddress,
    'admin_token' => admin_token,
    'admin_user' => admin_user,
    'admin_passwd' => admin_passwd
  )
end


service 'openstack-keystone' do
    action [:enable,:start]
end

template "/etc/keystone/user_data.sh" do
  source "user_data.sh"
  mode "0700"
  owner "root"
  group "root"
  variables(
    'admin_user' => admin_user,
    'admin_passwd' => admin_passwd,
    'nova_user' => nova_user,
    'nova_passwd' => nova_passwd,
    'glance_user' => glance_user,
    'glance_passwd' => glance_passwd
  )
  notifies :run, "execute[user_create]", :immediately
end

execute 'user_create' do
  command 'bash /etc/keystone/user_data.sh'
  action :nothing
end

