# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Types::WorkItems::Widgets::ProgressType do
  let(:fields) do
    %i[type progress updated_at start_value end_value current_value]
  end

  specify { expect(described_class.graphql_name).to eq('WorkItemWidgetProgress') }

  specify { expect(described_class).to have_graphql_fields(fields) }
end
