#
# Cookbook Name:: singularity
# Recipe:: source
#
# Copyright (C) 2015 EverTrue, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

node.set['apt']['compile_time_update'] = true
include_recipe 'build-essential'
include_recipe 'git'
include_recipe 'maven'

directory "#{Chef::Config[:file_cache_path]}/Singularity" do
  owner node['singularity']['user']
end

directory "#{node['singularity']['home']}/bin" do
  owner     node['singularity']['user']
  group     node['singularity']['user']
  mode      0755
  recursive true
end

git "#{Chef::Config[:file_cache_path]}/Singularity" do
  repository 'https://github.com/HubSpot/Singularity.git'
  reference  node['singularity']['git_ref']
  user       node['singularity']['user']
  action     :export
end

execute 'build_singularity' do
  action  :run
  # Maven (or rather npm) has issues with
  # being run as root.
  user    node['singularity']['user']
  environment('HOME' => node['singularity']['home'])
  command "#{node['maven']['m2_home']}/bin/mvn clean package -DskipTests"
  creates "#{Chef::Config[:file_cache_path]}/Singularity/" \
          'SingularityService/target/' \
          "SingularityService-#{node['singularity']['version']}-shaded.jar"
  cwd     "#{Chef::Config[:file_cache_path]}/Singularity"
end

remote_file "#{node['singularity']['home']}/bin/" \
            "SingularityService-#{node['singularity']['version']}-shaded.jar" do
  mode   0644
  source "file://#{Chef::Config[:file_cache_path]}/Singularity/" \
         'SingularityService/target/' \
         "SingularityService-#{node['singularity']['version']}-shaded.jar"
end
