require 'puppet'
require 'elasticsearch'
require 'date'
require 'yaml'

Puppet::Reports.register_report(:elk_report) do
  desc "Send reports to ELK stack"

  def process
    # Check if config exists
    confdir = Puppet.settings.values(nil, :main).interpolate(:confdir)
    if not File.exists?("#{confdir}/elk_report.yaml")
      Puppet.notice("ELK Report config file not present @ #{confdir}/elk_report.yaml, skipping...")
      return
    end

    # Load config
    begin
      # Set Run status - start by assuming 
      # Trying to make this reporting mimic the behavior of the console
      # IF a resource is in noop, and another resource is changed (ie you set a resource level noop),
      # the status of the run is reported as changed
      # IF ALL resources are noop (ie you passed the noop flag) - the status of the run is reported as noop
      # IF ANY resources are noop but did not simulate a change (ie no drift) - the status of the run is unchanged
      global_status = :unchanged

      metrics = Hash.new
      self.metrics['events'].values.each do |r|
        metrics[r[0]] = r[2]
      end

      if metrics.has_key?('noop') && metrics['success'] == 0 && metrics['failure'] == 0
        global_status = :noop
      elsif metrics['success'] > 0
        global_status = :changed
      elsif metrics['failure'] > 0
        global_status = :failed
      end

      # Load Conf file
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

      # Create a new document for each resource that was managed
      Puppet.notice("ELK Report: #{self.host} - create a new ElasticSearch document for each Puppet Resource")
      self.resource_statuses.each do |k,v|
        resource_body = Hash.new
        resource_body["host"]         = self.host
        resource_body["resource"]     = "#{v.resource_type.capitalize}[#{v.title}]"
        resource_body["time"]         = v.time
        resource_body["tags"]         = v.tags
        resource_body["eval_time"]    = v.evaluation_time
        resource_body["file"]         = v.file
        resource_body["line"]         = v.line
        resource_body["published"]    = true
        resource_body["published_at"] = Time.now.utc.iso8601

        if self.report_format >= 5
          resource_body["uuid"] = self.transaction_uuid
        else
          resource_body["uuid"] = nil
        end

        if v.events[0]
          resource_body["log"] = v.events[0].message
          resource_body["status"]  = v.events[0].status
        else
          resource_body["log"] = nil
          resource_body["status"]  = :unchanged
        end

        client.create index: "puppet_resource-#{Time.now.utc.to_date}",
          type: 'event',
          body: resource_body
      end

      # Create new document for the log view of the run
      Puppet.notice("ELK Report: #{self.host} - create a new Elasticsearch document for this Puppet transaction")
      logs = Array.new
      self.logs.each_with_index do |l,i|
        log = "#{l.level.capitalize}: "
        log << "#{l.source}: " if l.source and l.source != 'Puppet'
        log << l.message
        logs << log
      end

      client.create index: "puppet-#{Time.now.utc.to_date}",
        type: 'log',
        body: {
         configuration_version: "config version #{self.configuration_version}",
         environment: self.environment,
         log: logs.join("\n"),
         agent_version: "#{self.puppet_version}",
         status: global_status,
         host: self.host,
         time: self.time,
         type: self.kind,
         tags: ['puppet', 'puppet_log'],
         published: true,
         published_at: Time.now.utc.iso8601,
        }

    rescue Exception => e
      Puppet.err("Failed to process elk_report! #{e}\n#{e.backtrace}")
      Puppet.err(e.message)
    end

  end
end
