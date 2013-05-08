case node['platform']
when "centos"
  default['chef_client']['path'] = '/etc/sysconfig/chef-client'
when "ubuntu"
  default['chef_client']['path'] = '/etc/default/chef-client'
end
