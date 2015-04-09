#
# Cookbook Name:: packetbeat-cookbook
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

package 'default-jre'

directory "/tmp/packetbeat" do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

directory "/tmp/packetbeat/elasticsearch" do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

remote_file node['packetbeat']['elasticsearch']['path'] do
  source node['packetbeat']['elasticsearch']['url']
end


execute 'install_elasticsearch' do
  cwd ::File.dirname(node['packetbeat']['elasticsearch']['path'])
  command 'sudo dpkg -i elasticsearch-1.4.0.deb'
end

bash 'change_elasticsearch_yml' do
  cwd '/etc/elasticsearch'
  code <<-EOH
    echo " http.cors.enabled: true
          http.cors.allow-origin: \"http://localhost:8000\" " > elasticsearch.yml
    EOH
end


#启动服务
service "elasticsearch" do
  action [:enable,:start]
end


package "libpcap0.8"

directory "/tmp/packetbeat/packetbeat" do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

remote_file node['packetbeat']['packetbeat']['path'] do
  source node['packetbeat']['packetbeat']['url']
end

bash 'install_packetbeat' do
  cwd ::File.dirname(node['packetbeat']['packetbeat']['path'])
  code <<-EOH
    sudo dpkg -i packetbeat_0.4.3-1_amd64.deb
    EOH
end


#curl -XPUT 'http://localhost:9200/_template/packetbeat' -d@packetbeat.template.json

#用template和execute来构成

template '/etc/packetbeat/packetbeat.template.json' do
  source 'packetbeat.template.json.erb'
  notifies :run, 'execute[test]', :immediately
end

execute 'test' do
  command "curl -XPUT 'http://localhost:9200/_template/packetbeat' -d@packetbeat.template.json "
  action :nothing
end

service "packetbeat" do
  action [:enable,:start]
end

directory "/tmp/packetbeat/kibana" do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

remote_file node['packetbeat']['kibana']['path'] do
  source node['packetbeat']['kibana']['url']
end

bash "install_kibana" do
  cwd ::File.dirname(node['packetbeat']['kibana']['path'])
  code <<-EOH
    sudo tar -xzvf kibana-3.1.2-packetbeat.tar.gz
    cd kibana-3.1.2-packetbeat
    python -m SimpleHTTPServer
    EOH
end

directory "/tmp/packetbeat/dashboard" do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

remote_file node['packetbeat']['dashboard']['path'] do
  source node['packetbeat']['dashboard']['url']
end

bash "install_dashboard" do
  cwd ::File.dirname(node['packetbeat']['dashboard']['path'])
  code <<-EOH
    sudo tar xzvf v0.4.1.tar.gz
    cd dashboards-0.4.1
    ./load.sh
    EOH
end

