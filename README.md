# preserve-rds-snapshot

Amazon RDS create a snapshot automatically. Snapshot that is created automatically, will be lost when the instance is terminated. This script preserve db snapshots by copy snapshots.

### AWS API requirement

* RDS
  * describe_db_instances
  * describe_db_snapshots
  * copy_db_snapshot
  * delete_db_snapshots
  * list_tags_for_resources
  * add_tags_to_resources
  * remove_tags_from_resources
* EC2
  * describe_security_groups

NOTE: describe_security_groups is required to get the AWS Account Number. You can use the `--aws-account-number` option instead.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'preserve-rds-snapshot'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install preserve-rds-snapshot

## Usage

```
Commands:
  preserve-rds-snapshot copy -o src -t target  # copy snapshot
  preserve-rds-snapshot help [COMMAND]         # Describe available commands or one specific command
  preserve-rds-snapshot init                   # initialize instance
  preserve-rds-snapshot latest                 # show latest snapshot
  preserve-rds-snapshot list                   # Show list of RDS Snapshots
  preserve-rds-snapshot preserve               # copy automated snapshot to manual

Options:
  p, [--profile=PROFILE]                                   # Load credentials by profile name from shared credentials file.
  k, [--access-key-id=ACCESS_KEY_ID]                       # AWS access key id.
  s, [--secret-access-key=SECRET_ACCESS_KEY]               # AWS secret access key.
  r, [--region=REGION]                                     # AWS region.
      [--shared-credentials-path=SHARED_CREDENTIALS_PATH]  # AWS shared credentials path.
  i, [--instance=INSTANCE]                                 # target DB Instance
  n, [--aws-account-number=AWS_ACCOUNT_NUMBER]             # AWS Account Number (ex: 012345678901)
      [--dry-run], [--no-dry-run]                          # show only, don't modify
 ```

### initialize instance

```
$ preserve-rds-snapshot init
```

init subcommand add 'preserve-rds-snapshot' tag to RDS instance.

### preserve snapshot

```
$ preserve-rds-snapshot preserve
```

preserve subcommand copy automated snapshot to manual snapshot.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment. Run `bundle exec preserve-rds-snapshot` to use the code located in this directory, ignoring other installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/preserve-rds-snapshot/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
