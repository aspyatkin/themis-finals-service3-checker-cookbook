name 'themis-finals-service3-checker'
description 'Installs and configures Themis Finals service3 checker'
version '1.2.1'

recipe 'themis-finals-service3-checker', 'Installs and configures Themis Finals service3 checker'
depends 'git', '~> 6.0.0'
depends 'git2', '~> 1.0.0'
depends 'supervisor', '~> 0.4.12'
depends 'php', '~> 1.10.1'
depends 'composer', '~> 2.4.0'
depends 'apt'
depends 'chef_nginx', '~> 6.0.1'
depends 'ssh-private-keys', '~> 2.0.0'
depends 'ssh_known_hosts', '~> 5.1.0'
