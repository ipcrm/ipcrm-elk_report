class elk_report (
  String $user           = $::id,
  String $group          = $::gid,
  Hash $elkreport_config = undef,
){
  #Install elasticsearch gem
  package{'elasticsearch':
    ensure   => present,
    provider => 'puppet_gem',
  }

  package{'elasticsearch-puppetserver':
    ensure   => present,
    name     => 'elasticsearch',
    provider => 'puppetserver_gem',
    notify   => Service['pe-puppetserver'],
  }


  if $elkreport_config != undef {
    file {"${::settings::confdir}/elk_report.yaml":
      ensure  => present,
      owner   => $::id,
      group   => $::gid,
      content => template('elk_report/elk_report.yaml.erb'),
    }
  }

  # Configure Puppet to use elk_report setting
  pe_ini_subsetting { 'reports_elk_report' :
    ensure               => present,
    path                 => "${::settings::confdir}/puppet.conf",
    section              => 'master',
    setting              => 'reports',
    subsetting           => 'elk_report',
    subsetting_separator => ',',
    notify               => Service['pe-puppetserver'],
  }

}
