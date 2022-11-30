# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::Widgets::HealthStatusType, feature_category: :team_planning do
  let(:fields) do
    %i[type health_status]
  end

  specify { expect(described_class.graphql_name).to eq('WorkItemWidgetHealthStatus') }

  specify { expect(described_class).to have_graphql_fields(fields) }
end
