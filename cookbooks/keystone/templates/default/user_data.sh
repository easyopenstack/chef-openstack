#!/bin/bash

source ~/.novarc

keystone-manage db_sync

function get_id () {
    echo `"$@" | awk '/ id / { print $4 }'`
}

ADMIN_ROLE=$(get_id keystone role-create --name=admin)
MEMBER_ROLE=$(get_id keystone role-create --name=Member)
SERVICE_TENANT=$(get_id keystone tenant-create --name=service)
ADMIN_TENANT=$(get_id keystone tenant-create --name=admin)
ADMIN_USER=$(get_id keystone user-create --name=<%= @admin_user  %>\
                                         --pass=<%= @admin_passwd  %> \
                                         --email=admin@example.com)
keystone user-role-add --user $ADMIN_USER --role $ADMIN_ROLE --tenant_id $ADMIN_TENANT
GLANCE_USER=$(get_id keystone user-create \
        --name=<%= @glance_user  %> \
        --pass=<%= @glance_passwd %> \
        --tenant_id $SERVICE_TENANT \
        --email=glance@example.com)
keystone user-role-add \
        --tenant_id $SERVICE_TENANT \
        --user $GLANCE_USER \
        --role $ADMIN_ROLE
NOVA_USER=$(get_id keystone user-create \
        --name=<%= @nova_user  %>\
        --pass=<%= @nova_passwd  %> \
        --tenant_id $SERVICE_TENANT \
        --email=nova@example.com)
keystone user-role-add \
        --tenant_id $SERVICE_TENANT \
        --user $NOVA_USER \
        --role $ADMIN_ROLE
