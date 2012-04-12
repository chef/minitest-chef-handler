#
# Cookbook Name:: spec_examples
# Recipe:: default
#
# Copyright 2012, Opscode, Inc.
#

template "/tmp/foo" do
  variables({
    'phasers' => 'stun'
  })
  action :create
end

file "/tmp/foo" do
  action :touch
end

package "less" do
  action :install
end

package node['spec_examples']['pager'] do
  action :install
end

chipmunks = %w{alvin simon theodore}
chipmunks.each do |chipmunk|
  user chipmunk do
    action :create
  end
end

group "chipmunks" do
  members chipmunks
  action :create
end

%w{hard symbolic}.each do |link_type|
  link "/tmp/foo-#{link_type}" do
    to "/tmp/foo"
    link_type link_type
    action :create
  end
end

package "cron" do
  action :install
end

cron "noop" do
  hour "5"
  minute "0"
  command "/bin/true"
end

mount "/mnt" do
  pass 0
  fstype "tmpfs"
  device "/dev/null"
  options "nr_inodes=999k,mode=755,size=500m"
  action [:mount, :enable]
end

ifconfig "192.168.20.2" do
  device "eth0"
  action :add
end
