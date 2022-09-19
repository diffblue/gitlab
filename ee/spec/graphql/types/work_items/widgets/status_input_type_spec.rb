# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Types::WorkItems::Widgets::StatusInputType do
  it { expect(described_class.graphql_name).to eq('StatusInput') }

  it { expect(described_class.arguments.keys).to match_array(%w[status]) }
end
