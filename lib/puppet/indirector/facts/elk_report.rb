require 'puppet'
require 'elasticsearch'
require 'puppet/indirector/facts/puppetdb'

class Puppet::Node::Facts::Elk_report < Puppet::Node::Facts::Puppetdb
  desc "Save facts to ElasticSearchand PuppetDB.
       It uses PuppetDB to retrieve facts for catalog compilation."


  def save(request)
    # Check if config exists
    confdir = Puppet.settings.values(nil, :main).interpolate(:confdir)
    if not File.exists?("#{confdir}/elk_report.yaml")
      Puppet.notice("ELK Report config file not present @ #{confdir}/elk_report.yaml, skipping...")
      return
    end

    begin
      conf = YAML.load_file("#{confdir}/elk_report.yaml")

      # Create Connnection Object with Elasticsearch
      Puppet.notice("ELK Report: creating connection to Elasticsearch @ #{conf['host']}")
      client = Elasticsearch::Client.new hosts: {
        host: conf.fetch('host'),
        port: conf.fetch('port',nil),
        user: conf.fetch('user',nil),
        password: conf.fetch('password',nil),
        scheme: conf.fetch('scheme',nil)
      }


      Puppet.info "Request.instance.values type - #{request.instance.values.class}"
      newvalues = Hash[ request.instance.values.map {|k,v| [k.gsub(/\./,'_'),v] } ]


      Puppet.info "Submitting facts to ElasticSearch at #{conf['host']}"
      client.create index: "puppet_facts-#{Time.now.utc.to_date}",
        type: 'log',
        body: {
         host: request.key,
         facts: newvalues,
         tags: ['puppet', 'puppet_fact'],
         published: true,
         published_at: Time.now.utc.iso8601,
        }
    rescue Exception => e
      Puppet.err "Could not send facts to ElasticSearch: #{e}\n#{e.backtrace}"
    end

    super(request)
  end
end
