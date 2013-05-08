package "patch"
package "pcre-devel"
package "openssl"
package "openssl-devel" do
  action :install
end



script "install_nginx" do
  interpreter "bash"
  user "root"
  cwd "/usr/local/src"
  code <<-EOH
  wget 'http://nginx.org/download/nginx-1.2.1.tar.gz'
  tar -xzvf nginx-1.2.1.tar.gz -C /usr/local/src/
  git clone https://github.com/yaoweibin/nginx_tcp_proxy_module.git  /usr/local/src/nginx_tcp_proxy_module
  cd /usr/local/src/nginx-1.2.1/
  patch -p1 <  /usr/local/src/nginx_tcp_proxy_module/tcp.patch
  ./configure --add-module=/usr/local/src/nginx_tcp_proxy_module
  make
  make install
  EOH
  not_if 'ls /usr/local/src | grep nginx'
end

execute 'ln_nginx' do
  command "ln -s /usr/local/nginx/sbin/nginx /usr/sbin/nginx"
  not_if "ls /usr/sbin | grep nginx"
end

group "nginx" do
    gid 495
end


user "nginx" do
  uid 495
  gid "nginx"
  home "/var/log/nginx"
  shell "/sbin/nologin"
end

template '/usr/local/nginx/conf/nginx.conf' do
  source 'nginx.conf.erb'
  owner 'root'
  group 'root'
  mode '0700'
end

execute "start_nginx" do
    command "/usr/local/nginx/sbin/nginx"
    not_if "ps aux | grep nginx  | grep -v 'grep' | grep nginx"
end

