id = 'themis-finals-service3-checker'
h = ::ChefCookbook::Instance::Helper.new(node)

include_recipe "#{id}::php56"

directory node[id]['basedir'] do
  owner h.instance_user
  group h.instance_group
  mode 0755
  recursive true
  action :create
end

url_repository = "https://github.com/#{node[id]['github_repository']}"

if node.chef_environment.start_with? 'development'
  ssh_private_key h.instance_user
  ssh_known_hosts_entry 'github.com'
  url_repository = "git@github.com:#{node[id]['github_repository']}.git"
end

git2 node[id]['basedir'] do
  url url_repository
  branch node[id]['revision']
  user h.instance_user
  group h.instance_group
  action :create
end

if node.chef_environment.start_with?('development')
  git_data_bag_item = nil
  begin
    git_data_bag_item = data_bag_item('git', node.chef_environment)
  rescue
    ::Chef::Log.warn('Check whether git data bag exists!')
  end

  git_options = \
    if git_data_bag_item.nil?
      {}
    else
      git_data_bag_item.to_hash.fetch('config', {})
    end

  git_options.each do |key, value|
    git_config "git-config #{key} at #{node[id]['basedir']}" do
      key key
      value value
      scope 'local'
      path node[id]['basedir']
      user h.instance_user
      action :set
    end
  end
end

composer_project node[id]['basedir'] do
  dev false
  quiet false
  prefer_dist false
  user h.instance_user
  group h.instance_group
  action :install
end

script_dir = ::File.join(node[id]['basedir'], 'script')

namespace = "#{node['themis-finals']['supervisor_namespace']}.checker."\
            "#{node[id]['service_alias']}"

sentry_data_bag_item = nil
begin
  sentry_data_bag_item = data_bag_item('sentry', node.chef_environment)
rescue
end

sentry_dsn = \
  if sentry_data_bag_item.nil?
    {}
  else
    sentry_data_bag_item.to_hash.fetch('dsn', {})
  end

checker_environment = {
  'HOST' => '127.0.0.1',
  'PORT' => node[id]['server']['port_range_start'],
  'INSTANCE' => '%(process_num)s',
  'LOG_LEVEL' => node[id]['debug'] ? 'DEBUG' : 'INFO',
  'REDIS_HOST' => node['latest-redis']['listen']['host'],
  'REDIS_PORT' => node['latest-redis']['listen']['port'],
  'REDIS_DB' => node[id]['queue']['redis_db'],
  'THEMIS_FINALS_KEY_NONCE_SIZE' => node['themis-finals']['key_nonce_size'],
  'THEMIS_FINALS_AUTH_TOKEN_HEADER' => \
    node['themis-finals']['auth_token_header']
}

unless sentry_dsn.fetch(node[id]['service_alias'], nil).nil?
  checker_environment['SENTRY_DSN'] = \
    sentry_dsn.fetch node[id]['service_alias']
end

supervisor_service "#{namespace}.server" do
  command 'sh script/server'
  process_name 'server-%(process_num)s'
  numprocs node[id]['server']['processes']
  numprocs_start 0
  priority 300
  autostart node[id]['autostart']
  autorestart true
  startsecs 1
  startretries 3
  exitcodes [0, 2]
  stopsignal :INT
  stopwaitsecs 10
  stopasgroup true
  killasgroup true
  user h.instance_user
  redirect_stderr false
  stdout_logfile ::File.join(node['supervisor']['log_dir'], "#{namespace}.server-%(process_num)s-stdout.log")
  stdout_logfile_maxbytes '10MB'
  stdout_logfile_backups 10
  stdout_capture_maxbytes '0'
  stdout_events_enabled false
  stderr_logfile ::File.join(node['supervisor']['log_dir'], "#{namespace}.server-%(process_num)s-stderr.log")
  stderr_logfile_maxbytes '10MB'
  stderr_logfile_backups 10
  stderr_capture_maxbytes '0'
  stderr_events_enabled false
  environment checker_environment.merge(
    'THEMIS_FINALS_MASTER_KEY' => \
      data_bag_item('themis-finals', node.chef_environment)['keys']['master']
  )
  directory node[id]['basedir']
  serverurl 'AUTO'
  action :enable
end

template ::File.join(script_dir, 'tail-server-stdout') do
  source 'tail.sh.erb'
  owner h.instance_user
  group h.instance_group
  mode 0755
  variables(
    files: ::Range.new(0, node[id]['server']['processes'], true).map do |ndx|
      ::File.join(node['supervisor']['log_dir'], "#{namespace}.server-#{ndx}-stdout.log")
    end
  )
  action :create
end

template ::File.join(script_dir, 'tail-server-stderr') do
  source 'tail.sh.erb'
  owner h.instance_user
  group h.instance_group
  mode 0755
  variables(
    files: ::Range.new(0, node[id]['server']['processes'], true).map do |ndx|
      ::File.join(node['supervisor']['log_dir'], "#{namespace}.server-#{ndx}-stderr.log")
    end
  )
  action :create
end

supervisor_service "#{namespace}.queue" do
  command 'sh script/queue'
  process_name 'queue-%(process_num)s'
  numprocs node[id]['queue']['processes']
  numprocs_start 0
  priority 300
  autostart node[id]['autostart']
  autorestart true
  startsecs 1
  startretries 3
  exitcodes [0, 2]
  stopsignal :INT
  stopwaitsecs 10
  stopasgroup true
  killasgroup true
  user h.instance_user
  redirect_stderr false
  stdout_logfile ::File.join(node['supervisor']['log_dir'], "#{namespace}.queue-%(process_num)s-stdout.log")
  stdout_logfile_maxbytes '10MB'
  stdout_logfile_backups 10
  stdout_capture_maxbytes '0'
  stdout_events_enabled false
  stderr_logfile ::File.join(node['supervisor']['log_dir'], "#{namespace}.queue-%(process_num)s-stderr.log")
  stderr_logfile_maxbytes '10MB'
  stderr_logfile_backups 10
  stderr_capture_maxbytes '0'
  stderr_events_enabled false
  environment checker_environment.merge(
    'THEMIS_FINALS_CHECKER_KEY' => \
      data_bag_item('themis-finals', node.chef_environment)['keys']['checker'],
    'THEMIS_FINALS_FLAG_SIGN_KEY_PUBLIC' => data_bag_item('themis-finals', node.chef_environment)['sign_key']['public'].gsub("\n", "\\n"),
    'THEMIS_FINALS_FLAG_WRAP_PREFIX' => node['themis-finals']['flag_wrap']['prefix'],
    'THEMIS_FINALS_FLAG_WRAP_SUFFIX' => node['themis-finals']['flag_wrap']['suffix']
  )
  directory node[id]['basedir']
  serverurl 'AUTO'
  action :enable
end

template ::File.join(script_dir, 'tail-queue-stdout') do
  source 'tail.sh.erb'
  owner h.instance_user
  group h.instance_group
  mode 0755
  variables(
    files: ::Range.new(0, node[id]['queue']['processes'], true).map do |ndx|
      ::File.join(node['supervisor']['log_dir'], "#{namespace}.queue-#{ndx}-stdout.log")
    end
  )
  action :create
end

template ::File.join(script_dir, 'tail-queue-stderr') do
  source 'tail.sh.erb'
  owner h.instance_user
  group h.instance_group
  mode 0755
  variables(
    files: ::Range.new(0, node[id]['queue']['processes'], true).map do |ndx|
      ::File.join(node['supervisor']['log_dir'], "#{namespace}.queue-#{ndx}-stderr.log")
    end
  )
  action :create
end

supervisor_group namespace do
  programs [
    "#{namespace}.server",
    "#{namespace}.queue"
  ]
  action :enable
end

ngx_vhost = "themis-finals-checker-#{node[id]['service_alias']}"

nginx_site ngx_vhost do
  template 'nginx.conf.erb'
  variables(
    server_name: node[id]['fqdn'],
    service_name: node[id]['service_alias'],
    debug: node[id]['debug'],
    access_log: ::File.join(node['nginx']['log_dir'], "#{ngx_vhost}_access.log"),
    error_log: ::File.join(node['nginx']['log_dir'], "#{ngx_vhost}_error.log"),
    server_processes: node[id]['server']['processes'],
    server_port_start: node[id]['server']['port_range_start'],
    internal_networks: node['themis-finals']['config']['internal_networks']
  )
  action :enable
end
