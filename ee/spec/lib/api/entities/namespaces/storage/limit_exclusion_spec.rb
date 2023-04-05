# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Namespaces::Storage::LimitExclusion, feature_category: :consumables_cost_management do
  let(:exclusion) { create(:namespace_storage_limit_exclusion) }

  subject(:entity) { described_class.new(exclusion).as_json }

  it 'exposes correct attributes' do
    expect(entity.keys).to match_array [
      :id,
      :namespace_name,
      :namespace_id,
      :reason
    ]

    expect(entity[:namespace_name]).to eq exclusion.namespace.name
  end
end
