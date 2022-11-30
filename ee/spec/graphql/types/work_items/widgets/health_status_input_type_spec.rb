# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Types::WorkItems::Widgets::HealthStatusInputType, feature_category: :team_planning do
  it { expect(described_class.graphql_name).to eq('WorkItemWidgetHealthStatusInput') }

  it { expect(described_class.arguments.keys).to contain_exactly('healthStatus') }
end
