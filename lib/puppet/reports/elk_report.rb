require 'puppet'
require 'elasticsearch'
require 'date'

Puppet::Reports.register_report(:elk_report) do
  desc "Send reports to ELK stack"

  def process

    # Create Connnection Object with Elasticsearch
    client = Elasticsearch::Client.new host: 'localhost'

    # Create a new document for each resource that was managed
    self.resource_statuses.each do |k,v|
      resource_body = Hash.new
      resource_body["puppet_host"]      = self.host
      resource_body["puppet_path"]      = "#{v.resource_type.capitalize}[#{v.title}]"
      resource_body["puppet_time"]      = v.time
      resource_body["puppet_tags"]      = v.tags
      resource_body["puppet_eval_time"] = v.evaluation_time
      resource_body["puppet_file"]      = v.file
      resource_body["puppet_line"]      = v.line
      resource_body["published"]        = true
      resource_body["published_at"]     = Time.now.utc.iso8601

      if self.report_format >= 5
        resource_body["puppet_uuid"] = self.transaction_uuid
      else
        resource_body["puppet_uuid"] = nil
      end

      if v.events[0]
        resource_body["puppet_message"] = v.events[0].message
        resource_body["puppet_status"]  = v.events[0].status
      else
        resource_body["puppet_message"] = nil
        resource_body["puppet_status"]  = :unchanged
      end

      client.create index: "puppet_resource-#{Time.now.utc.to_date}",
        type: 'event',
        body: resource_body
    end


    # Create new document for the log view of the run
    messages = Array.new
    self.logs.each_with_index do |l,i|
      message = "#{l.level.capitalize}: "
      message << "#{l.source}: " if l.source and l.source != 'Puppet'
      message << l.message
      messages << message
    end

    client.create index: "puppet-#{Time.now.utc.to_date}",
      type: 'log',
      body: {
       puppet_configuration_version: "config version #{self.configuration_version}",
       puppet_environment: self.environment,
       puppet_message: messages,
       puppet_version: "#{self.puppet_version}",
       puppet_status: self.status,
       puppet_host: self.host,
       puppet_time: self.time,
       puppet_type: self.kind,
       tags: ['puppet', 'puppet_log'],
       published: true,
       published_at: Time.now.utc.iso8601,
      }
  end
end
