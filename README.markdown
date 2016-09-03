#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with elk_report](#setup)
    * [Setup requirements](#setup-requirements)
    * [Beginning with elk_report](#beginning-with-elk_report)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
    * [Logging](#logging)
    * [Elasticsearch](#elasticsearch)
5. [Limitations - OS compatibility, etc.](#limitations)


## Overview
This module adds a new report processor and facts terminus for Elasticsearch (ELK Stack)

## Module Description
The purpose of this module is to allow Puppet fact and reporting data(logs, resource events) to be sent into Elasticsearch and that data can be consumed via Kibana.  Once inside of Elasticsearch it allows you to perform full text searches against any elements of this data.

## Setup
There are two discrete places you need to configure for this module to function fully, reports and facts_terminus.

>
> NOTE: You can elect to only enable one or the other - there is no requirement to use both reports and facts
>

### Setup Requirements
These instructions assume your running Puppet Enterprise.  In addition, the class included in this module for setup installs ruby gems using the puppet_gem and puppetserver_gem providers - meaning you'll need internet connection from your master (or you should manually install these gems first).

### Beginning with elk_report
To enable the report processor classify your puppet masters with class `elk_report` and provide a configuration hash for the elasticsearch configuration in the `elkreport_config` parameter.

Example configuration hash:
```
{"host":"elastic.example.com"}
```
See [here](https://github.com/elastic/elasticsearch-ruby/tree/master/elasticsearch-transport#authentication) for more details on keys you can provide(for example to support authentication).

To enable the fact terminus you need to set `facts_terminus` parameter on class `puppet_enterprise::profile::master` which is assigned in the `PE Master` node classifier group.  After setting this parameter run puppet on your master(s) (which will restart services as needed to make the config take effect).

## Reference
All errors/info about elk_report are logged to puppetserver, `/var/log/puppetlabs/puppetserver/puppetserver.log` in Puppet Enterprise.

`RubyGems Used`
 - elasticsearch
 - elasticsearch-api
 - elasticsearch-transport

## Limitations
This is a prototype and hasn't been tested at scale.


