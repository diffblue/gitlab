# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Epics::RelatedEpicEntity, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:group_2) { create(:group) }
  let_it_be(:source) { create(:epic, group: group) }
  let_it_be(:target) { create(:epic, group: group_2) }
  let_it_be(:epic_link) { create(:related_epic_link, source: source, target: target) }

  let(:request) { EntityRequest.new(issuable: epic_link.source, current_user: user) }
  let(:related_epic) { epic_link.source.related_epics(user).first }
  let(:entity) { described_class.new(related_epic, { request: request, current_user: user }) }

  before do
    stub_licensed_features(epics: true, related_epics: true)
    group.add_developer(user)
  end

  shared_examples 'response matching json schema' do
    it 'matches json schema' do
      expect(entity.to_json).to match_schema('entities/related_epic', dir: 'ee')
    end

    it 'returns relation_path' do
      path = Gitlab::Routing.url_helpers.group_epic_related_epic_link_path(source.group, source.iid, epic_link.id)

      expect(entity.as_json[:relation_path]).to eq(path)
    end
  end

  describe '#to_json' do
    it_behaves_like 'response matching json schema'

    context 'when `epic_relations_for_non_members` feature flag is disabled' do
      before do
        stub_feature_flags(epic_relations_for_non_members: false)
      end

      context 'when user can read_epic_link_relation on target epic' do
        before do
          group_2.add_guest(user)
        end

        it_behaves_like 'response matching json schema'
      end

      context 'when user cannot read_epic_link_relation on target epic' do
        it 'matches json schema' do
          expect(entity.to_json).to match_schema('entities/related_epic', dir: 'ee')
        end

        it 'returns null relation_path' do
          expect(entity.as_json[:relation_path]).to eq(nil)
        end
      end
    end
  end
end
