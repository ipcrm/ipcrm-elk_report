class elk_report (
  String $user           = $::settings::user,
  String $group          = $::settings::group,
  Hash $elkreport_config = undef,
){
  # Configure Puppet to use elk_report setting
  ini_setting { 'puppet agent reports':
    ensure  => present,
    path    => $::settings::config,
    section => 'agent',
    setting => 'reports',
    value   => 'elk_report',
  }

  if $elkreport_config != undef {
    file {"${::settings::confdir}/elk_report.yaml":
      ensure  => present,
      owner   => $user,
      group   => $group,
      content => template('elk_report/elk_report.yaml.erb'),
    }
  }
}
