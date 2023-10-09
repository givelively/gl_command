# t-command

T::Command is an implementation of the [Command Pattern](https://en.wikipedia.org/wiki/Command_pattern) to encapsulate business logic.

The idea is to avoid bloat in Controllers and reduce coupling between models.

## Installation

Add the following line to your Gemfile:

```ruby
gem 't-command', git: 'https://github.com/timlawrenz/t-command.git'
```

Download and install the gem:
```sh
bundle install
```

## Interface

### Basic use case
```ruby
class DoComplexCommand
  include T::Command

  def call
    ... complex business logic ...
    ... complex business logic ...
    ... complex business logic ...
  end
end

class SomeController
  def index
    result = DoComplexCommand.call
  end
end
```
