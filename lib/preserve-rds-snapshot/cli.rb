require 'thor'
require 'thor/aws'

module PreserveRdsSnapshot
  class CLI < Thor
    include Thor::Aws
    PRESERVE_TAG_NAME = 'preserve-rds-snapshot'

    class_option :instance,
      aliases: [:i],
      type: :string,
      desc: 'target DB Instance'
    class_option :aws_account_number,
      aliases: [:n],
      type: :string,
      desc: 'AWS Account Number (ex: 012345678901)'
    class_option :dry_run,
      type: :boolean,
      desc: "show only, don't modify"

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
          instance = i.db_instance_identifier
          latest = latest_auto_snapshot(instance)
          if latest
            if options[:dry_run]
              puts "#{latest.db_snapshot_identifier}\t-\t-"
            else
              s = copy_snapshot(latest.db_snapshot_identifier)
              puts "copy\t#{latest.db_snapshot_identifier}\t#{s.db_snapshot_identifier}\t#{s.snapshot_create_time}" if s
            end
          end

          tag = preserve_tag(instance, 'db')
          expireds = expired_snapshots(instance, tag[:value].to_i)
          dry_run_msg = '(dry run)' if options[:dry_run]
          expireds.each do |expired|
            unless options[:dry_run]
              rds.client.delete_db_snapshot(
                db_snapshot_identifier: expired.db_snapshot_identifier
              )
            end
            puts "delete#{dry_run_msg}\t#{expired.db_snapshot_identifier}"
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
          tags: [key: PRESERVE_TAG_NAME, value: 'true']
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
          rds.db_instances.each do |i|
            list << i if preserve_tag(i.db_instance_identifier, 'db')
          end
        end
      rescue ::Aws::Errors::ServiceError => e
        $stderr.puts e
      end
      list
    end

    def preserve_snapshot_name(db_snapshot_identifier)
      'preserve-' + db_snapshot_identifier.gsub(/^rds:/, '')
    end

    def aws_account_number
      if options[:aws_account_number]
        return options[:aws_account_number]
      else
        begin
          return ec2.security_groups(group_names: ['default']).first.owner_id
        rescue ::Aws::Errors::ServiceError => e
          $stderr.puts e
        end
      end
    end

    def rds_arn(resource_id, type)
      "arn:aws:rds:#{options[:region]}:#{aws_account_number}:#{type}:#{resource_id}"
    end

    def preserve_tag(resource_id, type)
      tag = nil
      begin
        resp = rds.client.list_tags_for_resource(
          resource_name: rds_arn(resource_id, type)
        )
        tag = resp.tag_list.find {|t| t[:key] == PRESERVE_TAG_NAME}
      rescue ::Aws::Errors::ServiceError => e
        $stderr.puts e
      end
      tag
    end

    def copy_snapshot(db_snapshot_identifier)
      begin
        resp = rds.client.copy_db_snapshot(
          source_db_snapshot_identifier: db_snapshot_identifier,
          target_db_snapshot_identifier: preserve_snapshot_name(db_snapshot_identifier),
          tags: [key: PRESERVE_TAG_NAME, value: 'true']
        )
        return resp.db_snapshot
      rescue ::Aws::Errors::ServiceError => e
        $stderr.puts e
      end
    end

    def expired_snapshots(db_instance_identifier, generations)
      expired_snapshots = []
      begin
        resp = rds.client.describe_db_snapshots(
          snapshot_type: 'manual',
          db_instance_identifier: db_instance_identifier
        )
        snapshots = resp.db_snapshots.select {|s|
          preserve_tag(s.db_snapshot_identifier, 'snapshot')
        }.sort_by(&:snapshot_create_time).reverse
        expired_snapshots = snapshots[generations..-1] if snapshots.size > generations
      rescue ::Aws::Errors::ServiceError => e
        $stderr.puts e
      end
      expired_snapshots
    end
  end
end
