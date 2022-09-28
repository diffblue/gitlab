# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::Widgets::StatusType do
  let(:fields) do
    %i[type status]
  end

  specify { expect(described_class.graphql_name).to eq('WorkItemWidgetStatus') }

  specify { expect(described_class).to have_graphql_fields(fields) }
end
