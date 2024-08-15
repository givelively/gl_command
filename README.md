# GLCommand

`GLCommand` is a way to encapsulate business logic.

Calling a command returns a `GLCommand::Context` which has these properties:

- The arguments that were passed in to the command `.call` method (set via `allows` `requires`)
- The returns from the `.call` method
- `error` (which contains the error, if an error was raised)
- `full_error_message` - which renders a string from the error, or can be set explicitly (used to show a legible error to the user).
- `success` - `true` if the command executed without an error (false if there is an `error`)


## Installation

Add the following line to your Gemfile:

```ruby
gem 'gl_command'
```

Download and install the gem:
```sh
bundle install
```

## Using GLCommand

Invoke a command with `.call` or `.call!`

`.call` will return the `GLCommand::Context`, with `error` assigned (if there is an error)

`.call!` will raise the error (if there is an error), otherwise it will return the `GLCommand::Context`

General rules for deciding whether to use `.call!`

- In controllers use `.call` (make sure you check that it succeeds and [render errors](#displaying-errors) appropriately)
- In background jobs and rake tasks, use `.call!`
- Use `.call!` when calling a command within another command. If the inner command fails, it will assign errors to the outer command.

```ruby
class SomeCommand < GLCommand::Callable
  returns :data

  def call
    # If OtherCommand fails, SomeCommand will also fail - with the error from OtherCommand
    result = OtherCommand.call!
    context.data = result.data
  end
end
```

## Success/Failure

GLCommand context's are successful by default (`successful?` aliases `success?`).

They are a failure (`success? == false`) if the context has an error.

Here are the ways of adding an error to a command:

- Raising an exception
  - Immediately stops execution
- Calling `stop_and_fail!`
  - Immediately stops execution
- Failing a validation
  - Validation errors are checked before the `call` method is invoked (if `valid? == false` the command will return).
  - If validations are added during the `call` method, the command fails after call
- Directly assigning `context.error` or `context.full_error_message` to a non-nil value
  - Checked after `call` method finishes

If you invoke a command with `.call!` all of the above will raise an exception

If a command fails, it will call its `rollback` method before returning (even when invoked with `.call!`)

### Displaying errors

In addition to encapsulating business logic, GLCommand also standardizes error handling.

This means that rather than having to rescue errors in controllers, you can just render the command's `full_error_message`

```ruby
result = GLCommand::Callable.call(params)
if result.success?
  redirect_to new_controller_action
else
  flash[:error] = result.full_error_message
  redirect_back
end
```

In general, use `context.full_error_message` to render errors.


### `stop_and_fail!`

Use `stop_and_fail!` to immediately stop a command and raise an error (`GLCommand::StopAndFail` by default)

The argument to `stop_and_fail!` is assign to the `context.error`

- If you pass an exception, that exception will be raised and/or sent to Sentry
- Otherwise, the error will be a `GLCommand::StopAndFail` and what was passed will be assigned to `full_error_message`

```ruby
# Passing a string:
stop_and_fail!('An error message')
context.error # => GLCommand::StopAndFail
context.full_error_message # => 'An error message'

# Passing an exception:
stop_and_fail!(ActiveRecord::RecordNotFound)
context.error # => ActiveRecord::RecordNotFound
context.full_error_message # => ActiveRecord::RecordNotFound

# Passing an exception with an error message
stop_and_fail!(ActiveRecord::RecordNotFound.new('Some error message'))
context.error # => ActiveRecord::RecordNotFound
context.full_error_message # => 'Some error message'
```

You can also include `no_notify: true`, which prevents `GLExceptionNotifier` from being called.

```ruby
# Sentry is notified when #call fails by default:
stop_and_fail!('An error message') # GLExceptionNotifier is called

# If you don't want to alert Sentry when the command fails in a specific way:
stop_and_fail!('An error message', no_notify: true) # GLExceptionNotifier is *not* called
```


### Validations

You can add validations to `GLCommand::Callable` and `GLCommand::Chainable`.

If the validations fail, the command returns `success: false` without executing.

If validations fail, `GLExceptionNotifier` is not called


## GLExceptionNotifier

[ExceptionNotifier](https://github.com/givelively/gl_exception_notifier) is Give Lively's wrapper for notify our error monitoring service (currently [Sentry](https://github.com/getsentry/sentry-ruby))

When a command fails `GLExceptionNotifier` is called, unless:

- The command is invoked with `call!` (because an error will be raised, which will alert Sentry)
- The failure is a validation failure
- `stop_and_fail!` is called with `no_notify: true` - for example `stop_and_fail!('An error message', no_notify: true)`

**NOTE:** commands that invoke other commands with `call!` inherit the no_notify property of called command.

```ruby
class InteriorCommand < GLCommand::Callable
  def call
    stop_and_fail!('An error message', no_notify: true)
  end
end

class MainCommand < GLCommand::Callable
  def call
    # Use call! in commands that invoke other commands to have the errors automatically bubble up
    InteriorCommand.call!
  end
end

# This won't call GLExceptionNotifier, because no_notify: true was used on InteriorCommand
result = MainCommand.call
result.success? # => false
result.full_error_message # => 'An error message'
```

## Chainable

Bundle commands together with `GLCommand::Chainable`

- Automatically passes the requires/allows and returns between the commands
- Returns a `GLCommand::ChainableContext`, that inherits from `GLCommand::Context`. It adds a `Commands` array that contains the Command class names that were called.
- A command in the chain failing will call `rollback` on itself and then each command in the context `Command` array (in reverse order)


If you need to do logic in the `GLCommand::Chainable` class, define the `call` method and invoke `chain` from that.

```ruby
class SomeChain < GLCommand::Chainable
  requires :item

  returns :new_item

  chain CommmandOne, CommandTwo

  def call
    # Add some logic goes here
    chain(item:) # Automatically assigns the return to the context
    # Additional logic here
  end
end
```


---

This library is influenced by [interactors](https://github.com/collectiveidea/interactor) and inspired by the [Command Pattern](https://en.wikipedia.org/wiki/Command_pattern).
