# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::Widgets::TestReportsType, feature_category: :requirements_management do
  let(:fields) do
    %i[type test_reports]
  end

  specify { expect(described_class.graphql_name).to eq('WorkItemWidgetTestReports') }

  specify { expect(described_class).to have_graphql_fields(fields) }
end
