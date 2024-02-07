# GL::Command

GL::Command is an implementation of the [Command Pattern](https://en.wikipedia.org/wiki/Command_pattern) to encapsulate business logic.

The idea is to avoid bloat in Controllers and reduce coupling between models.

## Installation

Add the following line to your Gemfile:

```ruby
gem 'gl-command'
```

Download and install the gem:
```sh
bundle install
```

## Interface

### Basic use case
```ruby
class SomeController
  def index
    result = DoComplexCommand.call
  end
end

class DoComplexCommand
  include GL::Command

  def call
    ... complex business logic ...
  end
end
```

### Providing data
The call method accepts a hash of parameters as _context_. The Command has access to these parameters via the the `context` attribute.
```ruby
class SomeController
  def index
    result = DoComplexCommand.call(page: params[:page],
                                   sort: params[:sort])
  end
end

class DoComplexCommand
  include GL::Command

  def call
    BusinessObject.method_call(offset: context.page * 50,
                               ordering_by: context.sort)
    ... complex business logic ...
  end
end
```

### Returning data
The parameters of the `call` method get converted into a `GL::Context`.
```ruby
class SomeController
  def index
    result = DoComplexCommand.call(page: params[:page],
                                   sort: params[:sort])
    @business_data = result.bunsiness_result
  end
end

class DoComplexCommand
  include GL::Command

  def call
    context.business_result = BusinessObject.method_call(offset: context.page * 50,
                                                         ordering_by: context.sort)
  end
end
```

### Failure and success
Should the business logic not be successful, a `Context` can be failed via `context.fail!`.
The context comes with an `errors` of type `ActiveModel::Errors`.
```ruby
class SomeController
  def index
    result = DoComplexCommand.call(page: params[:page],
                                   sort: params[:sort])
    @business_data = result.bunsiness_result
    render and return if result.success?
    render_failure if result.failure?
  end
end

class DoComplexCommand
  include GL::Command

  def call
    context.business_result = BusinessObject.method_call(offset: context.page * 50,
                                                         ordering_by: context.sort)
    if business_result.blank?
       context.errors.add(:base, 'no data found.')
       context.fail!
    end
  end
end
```

Should an exception occur, the interactor fails automatically and adds exception details to `context.errors`.
```ruby
class DoComplexCommand
  include GL::Command

  def call
    raise StandardError
  end
end
```
### Rollback
Whenever a GL::Command fails, it executes `rollback` if defined.
```ruby
class DoComplexCommand
  include GL::Command

  def call
    # change a lot of things
    raise StandardError
  end

  def rollback
    # undo all the changes
  end
end
```

### Hooks
GL::Commands offer `before`, `around`, and `after` hooks.
```ruby
class DoComplexCommand
  include GL::Command

  before :initialize_logger
  around :measure_time
  after :close_transaction

  def call
    context.business_result = BusinessObject.method_call(offset: context.page * 50,
                                                         ordering_by: context.sort)
    if business_result.blank?
       context.errors.add(:base, 'no data found.')
       context.fail!
    end
  end

  private

  def initialize_logger
    # initialize logger
  end
  def measure_time
    time = Time.now
    call
    duration = Time.now - time
  end
  def close_transaction
    # closing transaction
  end
end
```

## Publishing gem to rubygems!

Make the gem

    gem build gl-command.gemspec

Push to rubygems

    gem push gl-command-1.0.0.gem


That's it. References:

[Publishing](http://guides.rubygems.org/publishing/)

[making your first gem](http://guides.rubygems.org/make-your-own-gem/)