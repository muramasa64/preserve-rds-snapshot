require 'thor'
require 'thor/aws'

module PreserveRdsSnapshot
  class CLI < Thor
    include Thor::Aws

    desc :list, 'Show list of RDS Snapshots'
    option :snapshot_type,
      aliases: [:t],
      type: :string,
      desc: "snapshot type (manual or automated)"
    def list
      begin
        resp = rds.client.describe_db_snapshots(
          snapshot_type: options[:snapshot_type]
        )
        resp.db_snapshots.each do |s|
          puts "#{s.db_snapshot_identifier}\t#{s.snapshot_create_time}"
        end
      rescue ::Aws::Errors::ServiceError => e
        $stderr.puts e
      end
    end

    desc :preserve, 'copy automated snapshot to manual'
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
    def preserve
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
      s = latest_auto_snapshot
      puts "#{s.db_snapshot_identifier}\t#{s.snapshot_create_time}" if s
    end

    private

    def latest_auto_snapshot
      latest = nil
      begin
        resp = rds.client.describe_db_snapshots(
          snapshot_type: 'automated'
        )
        #resp.db_snapshots.sort_by &:snapshot_create_time
        latest = resp.db_snapshots.sort_by {|s| s.snapshot_create_time}.last
      rescue ::Aws::Errors::ServiceError => e
        $stderr.puts e
      end
      latest
    end
  end
end
