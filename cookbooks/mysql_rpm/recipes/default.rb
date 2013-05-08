begin
	ipaddress = node['os_networks']['management'].split('.')[0..2].join('.')+'.'+node['id']
rescue
        ipaddress = node[:mysql][:address]
end

packages = %w{ mysql-server mysql }

packages.each do |pkg|
  package pkg
end


execute 'restart_mysql' do
  command '/etc/init.d/mysqld restart'
  not_if 'netstat -ln |  grep 3306'
end

service 'mysqld' do
    action [:enable,:start]
end
