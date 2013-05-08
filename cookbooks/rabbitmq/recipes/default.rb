packages = case node['platform']
  when "centos","redhat","fedora","scientific","amazon"
    %w{ rabbitmq-server }
  when "ubuntu"
    %w{ rabbitmq-server }
  end

package "rabbitmq-server" do
  action :install
end

ipaddress = node['os_networks']['management'].split('.')[0..2].join('.')+'.'+node['id']
nodename = node['ipaddress'].gsub(/[.]/,'-')

rabbituser =  node['rabbitmq']['username']
rabbitpass =  node['rabbitmq']['password']

port = node[:rabbitmq][:port]


template "/etc/rabbitmq/rabbitmq-env.conf" do
  source "rabbitmq-evn.conf.erb"
  mode '0644'
  owner 'root'
  group 'root'
  variables(
	"rabbit_name" => nodename,
	"rabbit_ip" => ipaddress,
	"rabbit_port" => port
	)
  notifies :run, "execute[restart_rabbit]", :immediately
end


execute 'restart_rabbit' do
  command "/etc/init.d/rabbitmq-server restart"
  action :nothing
end

execute 'delete_default_user' do
	command 'rabbitmqctl delete_user guest'
	only_if 'rabbitmqctl list_users | grep guest'
end

service 'rabbitmq-server' do
    action [:start,:enable]
end

execute 'adduser' do
	command 'rabbitmqctl  add_user '+rabbituser+' '+rabbitpass+'&&rabbitmqctl set_permissions -p / '+rabbituser+'  ".*" ".*" ".*"'
	not_if 'rabbitmqctl list_users | grep '+rabbituser
end
