> [!WARNING]
> This project is not affiliated with the Hanami team, but a mere user of Hanami itself.  The name Hanami Omakase was chosen to indicate it works with Hanami specifically and not other frameworks. DO NOT REPORT ISSUES FROM HERE TO HANAMI.

# hanami-omakase [![Gem Version](https://badge.fury.io/rb/hanami-omakase.svg)][rubygem] [![CI Status](https://github.com/afomera/hanami-omakase/workflows/CI/badge.svg)][actions]

Hanami Omakase is a collection of defaults picked for you, to get productive with Hanami fast, along with some extensions and utilities to make you happy.

Inspired by mega-frameworks in the Ruby space where defaults out of the box allow you to get productive, but with the ability to retain and fall back to the modular aspect of Hanami.

## License

See `LICENSE` file.

## Installation

```sh
bundle add hanami-omakase
```

In `config/app.rb`:

```rb
require "hamami"
require "hamami/omakase"
```

That's all for now, you'll have access to the Core Extensions listed below throughout your Hanami application.

## Features:

### Core Extensions

#### Integer

- Adds support for `seconds`, `minutes`, `hours`, `days`, `weeks` and `years` methods on Integers to return a given number multiplied by the respective values to return the integer in seconds.

```ruby
1.second #=> 1
5.seconds #=> 5
1.minute #=> 60
1.hours #=> 3600
1.day #=> 86400
1.week #=> 604800
365.days #=> 31536000
1.year #=> 31536000
```

There are plural and singular methods for those mentioned above.
