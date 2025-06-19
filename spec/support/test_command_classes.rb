# frozen_string_literal: true

class CumulativeDefinitionCommand < GLCommand::Callable
  requires :req1
  requires req2: String

  allows :allow1
  allows allow2: Integer

  returns :ret1
  returns :ret2

  def call; end
end
