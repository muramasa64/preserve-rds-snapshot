# preserve-rds-snapshot

Amazon RDS create a snapshot automatically. Snapshot that is created automatically, will be lost when the instance is terminated. This script preserve db snapshots by copy snapshots.

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

Commands:
  preserve-rds-snapshot help [COMMAND]                                                                               ...
  preserve-rds-snapshot list                                                                                         ...
  preserve-rds-snapshot preserve o, --source-db-snapshot-identifier=SOURCE_DB_SNAPSHOT_IDENTIFIER t, --target-db-snap...

Options:
  p, [--profile=PROFILE]                                   # Load credentials by profile name from shared credentials file.
  k, [--access-key-id=ACCESS_KEY_ID]                       # AWS access key id.
  s, [--secret-access-key=SECRET_ACCESS_KEY]               # AWS secret access key.
  r, [--region=REGION]                                     # AWS region.
      [--shared-credentials-path=SHARED_CREDENTIALS_PATH]  # AWS shared credentials path.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment. Run `bundle exec preserve-rds-snapshot` to use the code located in this directory, ignoring other installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/preserve-rds-snapshot/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
