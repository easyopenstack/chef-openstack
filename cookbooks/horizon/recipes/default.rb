packages = %w{ openstack-dashboard nginx python-pip gcc make python-devel }

packages.each do |pkg|
  package pkg
end

execute "install_django" do
    command "pip-python install uwsgi django"
    not_if "ls /usr/bin | grep uwsgi"
end

file "/usr/local/nginx/conf/vhosts/test.conf" do
    action :delete
end

directory "/var/log/nginx" do
  owner "nginx"
  group "nginx"
  mode "0660"
  action :create
end


template "/usr/share/openstack-dashboard/openstack_dashboard/wsgi/wsgi.py" do
    source "wsgi.py.erb"
    mode "0644"
end


template "/usr/share/openstack-dashboard/openstack_dashboard/wsgi/uwsgi.ini" do
    source "uwsgi.ini.erb"
    mode "0644"
end


template "/usr/share/openstack-dashboard/openstack_dashboard/local/local_settings.py" do
    source "local_settings.py.erb"
    mode "0644"
end


template "/usr/local/nginx/conf/nginx.conf" do
    source "nginx.conf.erb"
    mode "0644"
end


template "/usr/local/nginx/conf/vhosts/horizon.conf" do
    source "horizon.conf.erb"
    mode "0644"
end

template "/usr/lib/python2.6/site-packages/horizon/templates/horizon/auth/_login.html" do
    source "_login.html.erb"
    mode "0644"
end



template "/etc/init.d/uwsgi" do
    source "uwsgi.erb"
    mode "0700"
end

service "uwsgi" do
    action [:enable,:start]
end

execute "start_nginx" do
    command "/usr/local/nginx/sbin/nginx"
    not_if "ps aux | grep nginx | grep -v grep"
end
