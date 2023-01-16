# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::Widgets::RequirementLegacyType, feature_category: :requirements_management do
  let(:fields) do
    %i[type legacy_iid]
  end

  specify { expect(described_class.graphql_name).to eq('WorkItemWidgetRequirementLegacy') }

  specify { expect(described_class).to have_graphql_fields(fields) }
end
