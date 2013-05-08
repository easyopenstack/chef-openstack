#
# Cookbook Name:: sysctl
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#


template "/etc/sysctl.conf" do
  source "sysctl.conf.erb"
  action :create
  notifies :run, "execute[sysctl]", :immediately
end


execute "sysctl" do
  command "sysctl -p"
  action :nothing
end
