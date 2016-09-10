id = 'themis-finals-service3-checker'

default[id]['basedir'] = '/var/themis/finals/checker/service3'
default[id]['github_repository'] = 'aspyatkin/themis-finals-service3-checker'
default[id]['revision'] = 'master'
default[id]['user'] = 'vagrant'
default[id]['group'] = 'vagrant'

default[id]['debug'] = false
default[id]['service_alias'] = 'service3'

default[id]['server']['processes'] = 2
default[id]['server']['port_range_start'] = 10_200

default[id]['queue']['processes'] = 2
default[id]['queue']['redis_db'] = 12

default[id]['autostart'] = false
