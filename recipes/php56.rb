apt_repository 'php' do
  uri 'ppa:ondrej/php'
  distribution node['lsb']['codename']
end

node.default['php']['version'] = '5.6.25'
node.default['php']['conf_dir'] = '/etc/php/5.6/cli'
node.default['php']['src_deps'] = %w(libbz2-dev libc-client2007e-dev libcurl4-gnutls-dev libfreetype6-dev libgmp3-dev libjpeg62-dev libkrb5-dev libmcrypt-dev libpng12-dev libssl-dev pkg-config)
node.default['php']['packages'] = %w(php5.6-cgi php5.6 php5.6-dev php5.6-cli php-pear)
node.default['php']['mysql']['package'] = 'php5.6-mysql'
node.default['php']['curl']['package'] = 'php5.6-curl'
node.default['php']['apc']['package'] = 'php-apc'
node.default['php']['apcu']['package'] = 'php-apcu'
node.default['php']['gd']['package'] = 'php5.6-gd'
node.default['php']['ldap']['package'] = 'php5.6-ldap'
node.default['php']['pgsql']['package'] = 'php5.6-pgsql'
node.default['php']['sqlite']['package'] = 'php5.6-sqlite3'
node.default['php']['fpm_package'] = 'php5.6-fpm'
node.default['php']['fpm_pooldir'] = '/etc/php/5.6/fpm/pool.d'
node.default['php']['fpm_service'] = 'php5.6-fpm'
node.default['php']['fpm_socket'] = '/var/run/php/php5.6-fpm.sock'
node.default['php']['fpm_default_conf'] = '/etc/php/5.6/fpm/pool.d/www.conf'
node.default['php']['enable_mod'] = '/usr/sbin/phpenmod'
node.default['php']['disable_mod'] = '/usr/sbin/phpdismod'
node.default['php']['ext_conf_dir'] = '/etc/php/5.6/mods-available'

include_recipe 'php::default'
include_recipe 'composer::default'

package 'php5.6-mcrypt' do
  action :install
end

package 'php5.6-curl' do
  action :install
end

package 'php5.6-zip' do
  action :install
end

package 'php5.6-mbstring' do
  action :install
end

package 'php5.6-gmp' do
  action :install
end
