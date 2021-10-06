# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestSerializer do
  let_it_be(:user) { create(:user) }
  let_it_be(:resource) { create(:merge_request, :merged, description: "Description") }

  let(:json_entity) do
    described_class.new(current_user: user)
      .represent(resource, serializer: serializer)
      .with_indifferent_access
  end

  context 'compliance_dashboard merge request serialization' do
    let(:serializer) { 'compliance_dashboard' }

    it 'includes compliance_dashboard attributes' do
      expect(json_entity).to include(
        :id, :title, :merged_at, :milestone, :path, :issuable_reference, :approved_by_users
      )
    end
  end
end
