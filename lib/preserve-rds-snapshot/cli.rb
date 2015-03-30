require 'thor'
require 'thor/aws'

module PreserveRdsSnapshot
  class CLI < Thor
    include Thor::Aws

    desc :list, 'Show list of RDS Snapshots'

    def list
      p rds.client.describe_db_snapshots.to_a
    end
  end
end
