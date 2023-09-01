# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EpicSerializer, feature_category: :duo_chat do
  let_it_be(:group) { build_stubbed(:group) }
  let_it_be(:resource) { build_stubbed(:epic, group: group) }
  let_it_be(:user) { build(:user) }

  let(:json_entity) do
    described_class.new(current_user: user)
      .represent(resource, serializer: serializer)
      .with_indifferent_access
  end

  before do
    stub_licensed_features(epics: true)
  end

  context 'when no serializer defined' do
    let(:serializer) { nil }

    it 'matches epic json schema' do
      expect(json_entity.to_json).to match_schema('entities/epic', dir: 'ee')
    end
  end

  context 'when ai serializer requested' do
    let(:json_entity) do
      described_class.new(current_user: user)
                     .represent(resource, serializer: 'ai', resource: Ai::AiResource::Epic.new(resource))
                     .with_indifferent_access
    end

    it 'matches epic ai entity json schema' do
      expect(json_entity.to_json).to match_schema('entities/epic_ai_entity', dir: 'ee')
    end
  end
end
