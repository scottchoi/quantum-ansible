#!/bin/sh -x
HOST_IP=10.0.10.10
SERVICE_TOKEN=012345SECRET99TOKEN012345
PASSWORD=password
export SERVICE_TOKEN="${SERVICE_TOKEN}"
export SERVICE_ENDPOINT="http://${HOST_IP}:35357/v2.0"

get_id () {
    echo `$@ | awk '/ id / { print $4 }'`
}

# Tenants
TEST_ADMIN_TENANT=$(get_id keystone tenant-create --name=test-admin)
TEST_TENANT=$(get_id keystone tenant-create --name=test)
TEST_ALT_TENANT=$(get_id keystone tenant-create --name=test-alt)

# Users
TEST_ADMIN_USER=$(get_id keystone user-create --name=test-admin --pass="$PASSWORD" --email=admin@test.com)
TEST_USER=$(get_id keystone user-create --name=test --pass="$PASSWORD" --email=test@test.com)
TEST_ALT_USER=$(get_id keystone user-create --name=test-alt --pass="$PASSWORD" --email=test-alt@test.com)

# Roles
keystone role-create --name=admin
keystone role-create --name=Member
ADMIN_ROLE=$(keystone role-list | awk '/ admin / { print $2}')
MEMBER_ROLE=$(keystone role-list | awk '/ Member / { print $2}')

# Users/Roles
keystone user-role-add --tenant-id $TEST_ADMIN_TENANT --user-id $TEST_ADMIN_USER --role-id $ADMIN_ROLE
keystone user-role-add --tenant-id $TEST_TENANT --user-id $TEST_USER --role-id $MEMBER_ROLE
keystone user-role-add --tenant-id $TEST_ALT_TENANT --user-id $TEST_ALT_USER --role-id $MEMBER_ROLE

export OS_USERNAME=test-admin
export OS_TENANT_NAME=test-admin
export OS_PASSWORD=password
export OS_AUTH_URL=http://10.0.10.10:5000/v2.0/
export OS_REGION_NAME=RegionOne

# Flavors
nova flavor-create micro6 6 60 0 1
nova flavor-create micro7 7 70 0 1

# Security Groups
quantum security-group-create --tenant-id $TEST_ADMIN_TENANT test
quantum security-group-create --tenant-id $TEST_TENANT test
quantum security-group-create --tenant-id $TEST_ALT_TENANT test

# Network
quantum net-create ext-net --router:external true
quantum subnet-create --gateway 192.168.101.1 ext-net 192.168.101.0/24 --enable_dhcp False

quantum router-create --tenant-id $TEST_TENANT router1
quantum router-gateway-set router1 ext-net

quantum net-create --tenant-id $TEST_TENANT net1 
quantum subnet-create --tenant-id $TEST_TENANT net1 10.0.33.0/24 --name=sub1
quantum router-interface-add router1 sub1

nova image-list
quantum net-external-list
