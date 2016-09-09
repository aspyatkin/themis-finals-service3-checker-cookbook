name 'themis-finals-service3-checker'
description 'Installs and configures Themis Finals service3 checker'
version '1.0.0'

recipe 'themis-finals-service3-checker', 'Installs and configures Themis Finals service3 checker'
depends 'latest-git', '~> 1.1.11'
depends 'git2', '~> 1.0.0'
depends 'supervisor', '~> 0.4.12'
depends 'modern_nginx', '~> 1.3.0'
depends 'ssh_known_hosts', '~> 2.0.0'
depends 'themis-finals', '~> 1.1.15'
depends 'php', '~> 1.10.1'
depends 'composer', '~> 2.4.0'
depends 'apt'
