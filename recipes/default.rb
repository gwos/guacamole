#
# Cookbook Name:: guacamole
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "apt"
include_recipe "tomcat"

apt_update = true
cache_dir = Chef::Config[:file_cache_path]

%W{ libvncserver0 libfreerdp1 libvorbisenc2 }.each do |pkg|
    package pkg do
        action :install
        options "--force-yes"
        notifies :run, "execute[apt-get-update]", :immediately if apt_update
    end
    apt_update = false
end

remote_file "#{cache_dir}/#{node["guacamole"]["tar_file"]}.tar.gz" do
    source node["guacamole"]["url"]
    mode "0644"
    action :create_if_missing
end

bash "untar guacamole" do
    user "root"
    cwd cache_dir
    code <<-EOH
        tar -zxf #{node["guacamole"]["tar_file"]}.tar.gz
    EOH
end

%w{ guacd libguac-client-vnc0 guacamole }.each do |pkg|
    package pkg do
        action :install
    end
end

guacamole_war_file = node['guacamole']['war_file']
guacamole_webapp_dir = File.join(node["tomcat"]['webapps_dir'], "guacamole")
guacamole_war = "#{guacamole_webapp_dir}.war"

directory guacamole_webapp_dir do
    recursive true
    action :nothing
    notifies :restart, "service[#{node["tomcat"]["version"]}]"
end

cmd = "cp -f #{guacamole_war_file} #{guacamole_war}"

execute cmd do
    not_if "cmp -s #{guacamole_war_file} #{guacamole_war}"
end

link "#{node["tomcat"]["home"]}/lib/guacamole.properties" do
    to "/etc/guacamole/guacamole.properties"
end

template "/etc/guacamole/user-mapping.xml" do
    source "user-mapping.xml.erb"
    owner "root"
    mode "0644"
end

service node["tomcat"]["version"]do
    action :restart
end
