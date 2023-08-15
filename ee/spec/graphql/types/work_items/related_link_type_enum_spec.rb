# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::RelatedLinkTypeEnum, feature_category: :portfolio_management do
  it 'has the correct type' do
    expect(described_class.values).to match(
      'RELATED' => have_attributes(
        description: 'Related type.',
        value: 'relates_to'
      ),
      'BLOCKED_BY' => have_attributes(
        description: 'Blocked by type.',
        value: 'is_blocked_by'
      ),
      'BLOCKS' => have_attributes(
        description: 'Blocks type.',
        value: 'blocks'
      )
    )
  end
end
