# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::Widgets::VerificationStatusType do
  let(:fields) do
    %i[type verification_status]
  end

  specify { expect(described_class.graphql_name).to eq('WorkItemWidgetVerificationStatus') }

  specify { expect(described_class).to have_graphql_fields(fields) }
end
