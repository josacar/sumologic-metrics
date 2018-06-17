# Sumologic::Metrics

[![Build Status](https://www.travis-ci.org/josacar/sumologic-metrics.svg?branch=master)](https://www.travis-ci.org/josacar/sumologic-metrics)
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fjosacar%2Fsumologic-metrics.svg?type=shield)](https://app.fossa.io/projects/git%2Bgithub.com%2Fjosacar%2Fsumologic-metrics?ref=badge_shield)

Upload metrics to Sumologic!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sumologic-metrics'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sumologic-metrics

## Usage

```ruby
require 'sumologic-metrics'

url = ENV.fetch('SUMOLOGIC_ENDPOINT')

metrics = Sumologic::Metrics.new(collector_uri: url)
metrics.push('cluster=prod node=lb-1 metric=cpu  ip=2.2.3.4 team=infra 99.12 1528020619')
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/josacar/sumologic-metrics. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).


[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fjosacar%2Fsumologic-metrics.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2Fjosacar%2Fsumologic-metrics?ref=badge_large)

## Code of Conduct

Everyone interacting in the Sumologic::Metrics project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/josacar/sumologic-metrics/blob/master/CODE_OF_CONDUCT.md).

## Thanks

- SegmentIO for their [analytics-ruby](https://github.com/segmentio/analytics-ruby) gem