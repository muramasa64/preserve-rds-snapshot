require 'thor'
require 'thor/aws'

module PreserveRdsSnapshot
  class CLI < Thor
    include Thor::Aws

    class_option :instance,
      aliases: [:i],
      type: :string,
      desc: 'target DB Instance'

    desc :list, 'Show list of RDS Snapshots'
    option :snapshot_type,
      aliases: [:t],
      type: :string,
      desc: "snapshot type (manual or automated)"
    def list
      begin
        resp = rds.client.describe_db_snapshots(
          snapshot_type: options[:snapshot_type],
          db_instance_identifier: options[:instance]
        )
        resp.db_snapshots.each do |s|
          puts "#{s.db_snapshot_identifier}\t#{s.snapshot_create_time}"
        end
      rescue ::Aws::Errors::ServiceError => e
        $stderr.puts e
      end
    end

    desc :preserve, 'copy automated snapshot to manual'
    def preserve
      begin
        instances = db_instances(options[:instance])
        instances.each do |i|
          latest = latest_auto_snapshot(i.db_instance_identifier)
          if latest
            db_snapshot_identifier = latest.db_snapshot_identifier
            resp = rds.client.copy_db_snapshot(
              source_db_snapshot_identifier: db_snapshot_identifier,
              target_db_snapshot_identifier: preserve_snapshot_name(db_snapshot_identifier),
              tags: [key: 'type', value: 'preserve']
            )
            s = resp.db_snapshot
            puts "#{s.db_snapshot_identifier}\t#{s.snapshot_create_time}"
          end
        end
      rescue ::Aws::Errors::ServiceError => e
        $stderr.puts e
      end
    end

    desc :copy, 'copy  snapshot'
    option :source_db_snapshot_identifier,
      aliases: [:o],
      type: :string,
      desc: 'source snapshot identifier',
      required: true
    option :target_db_snapshot_identifier,
      aliases: [:t],
      type: :string,
      desc: 'target snapshot identifier',
      required: true
    def copy
      begin
        resp = rds.client.copy_db_snapshot(
          source_db_snapshot_identifier: options[:source_db_snapshot_identifier],
          target_db_snapshot_identifier: options[:target_db_snapshot_identifier],
          tags: [key: 'type', value: 'preserve']
        )
        s = resp.db_snapshot
        puts "#{s.db_snapshot_identifier}\t#{s.snapshot_create_time}"
      rescue ::Aws::Errors::ServiceError => e
        $stderr.puts e
      end
    end

    desc :latest, 'show latest snapshot'
    def latest
      instances = db_instances(options[:instance])
      instances.each do |instance|
        s = latest_auto_snapshot(instance.db_instance_identifier)
        puts "#{s.db_snapshot_identifier}\t#{s.snapshot_create_time}" if s
      end
    end

    private

    def latest_auto_snapshot(db_instance_identifier = nil)
      latest = nil
      begin
        resp = rds.client.describe_db_snapshots(
          snapshot_type: 'automated',
          db_instance_identifier: db_instance_identifier
        )
        latest = resp.db_snapshots.sort_by(&:snapshot_create_time).last
      rescue ::Aws::Errors::ServiceError => e
        $stderr.puts e
      end
      latest
    end

    def db_instances(db_instance_identifier = nil)
      list = []
      begin
        if db_instance_identifier
          list << rds.db_instance(db_instance_identifier)
        else
          list = rds.db_instances.to_a
        end
      rescue ::Aws::Errors::ServiceError => e
        $stderr.puts e
      end
    end

    def preserve_snapshot_name(db_snapshot_identifier)
      'preserve-' + db_snapshot_identifier.gsub(/^rds:/, '')
    end
  end
end
