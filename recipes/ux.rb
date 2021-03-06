#
# Cookbook Name:: chef-jellyfish
# Recipe:: ux
#
# Copyright 2015, Booz Allen Hamilton
#
# All rights reserved - Do Not Redistribute
#

log 'Create jellyfish user'

user 'jellyfish' do
  comment 'jellyfish user'
  shell '/bin/bash'
end

log 'Install Pre-Requisites'
yum_package 'git'
yum_package 'gcc-c++'
yum_package 'make'
yum_package 'ruby'
yum_package 'rubygems'
yum_package 'unzip'
gem_package 'sass'

log 'Install node.js and dependencies'
bash 'Install Node' do
  user 'root'
  cwd '/tmp'
  code <<-EOH
  curl -sL https://rpm.nodesource.com/setup | bash -
  yum install -y nodejs
  npm install --global gulp
  EOH
  creates '/usr/bin/gulp'
end

log 'Checkout and Unzip the latest UX Code'
remote_file '/opt/ux-master.zip' do
  source 'https://github.com/projectjellyfish/ux/archive/master.zip'
  mode '0644'
end

bash 'unzip ux-master.zip' do
  cwd '/opt'
  user 'root'
  code <<-EOH
  unzip ux-master.zip
  EOH
  creates '/opt/ux-master'
end

log 'Run gulp and Install into Production'
bash 'Install Production' do
  user 'root'
  cwd '/opt/ux-master'
  code <<-EOH
  /usr/bin/npm install
  /usr/bin/gulp production
  EOH
  creates '/opt/ux-master/node_modules/winston'
end

log 'Set ENV settings'
template '/opt/ux-master/public/appConfig.js' do
  source 'appConfig.js.erb'
  mode '0644'
  owner 'root'
  group 'root'
end

log 'Install forever'

log 'run node'
bash 'Install forever' do
  user 'root'
  cwd '/opt/ux-master'
  code <<-EOH
  /usr/bin/npm install forever  -g &
  EOH
  creates '/usr/bin/forever'
end

bash 'run node' do
  user 'root'
  cwd '/opt/ux-master'
  code <<-EOH
  /usr/bin/forever start app.js &
  touch /tmp/node_is_running
  EOH
  creates '/tmp/node_is_running'
end

log 'Install nginx'
cookbook_file '/etc/yum.repos.d/nginx.repo' do
  source 'nginx.repo'
  mode '0644'
  owner 'root'
  group 'root'
end

yum_package 'nginx'

cookbook_file '/etc/nginx/conf.d/default.conf' do
  source 'default.conf'
  mode '0644'
  owner 'root'
  group 'root'
end

service 'nginx' do
  action :start
end
