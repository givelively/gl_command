# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GlCommand do
  it 'has a version number' do
    expect(GlCommand::VERSION).to be_a(String)
  end
end
