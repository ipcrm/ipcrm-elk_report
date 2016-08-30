class elk_report (
  String $user           = $::id,
  String $group          = $::gid,
  Hash $elkreport_config = undef,
){
  # Configure Puppet to use elk_report setting
  ini_setting { 'puppet agent reports':
    ensure  => present,
    path    => $::settings::config,
    section => 'main',
    setting => 'reports',
    value   => 'elk_report',
  }

  if $elkreport_config != undef {
    file {"${::settings::confdir}/elk_report.yaml":
      ensure  => present,
      owner   => $::id,
      group   => $::gid,
      content => template('elk_report/elk_report.yaml.erb'),
    }
  }
}
