# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::EpicAncestorsResolver do
  include GraphqlHelpers

  let_it_be_with_refind(:group) { create(:group, :private) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:epic1) { create(:epic, group: group) }
  let_it_be(:epic2) { create(:epic, group: group, parent: epic1) }
  let_it_be_with_reload(:base_epic) { create(:epic, group: group, parent: epic2) }
  let_it_be(:confidential_epic1) { create(:epic, :confidential, group: group) }
  let_it_be(:confidential_epic2) { create(:epic, :confidential, group: group, parent: confidential_epic1) }
  let_it_be_with_reload(:confidential_epic) { create(:epic, :confidential, group: group, parent: confidential_epic2) }

  let(:args) { { include_ancestor_groups: true } }

  before do
    stub_licensed_features(epics: true)
  end

  describe '#resolve' do
    it 'returns nothing when feature disabled' do
      stub_licensed_features(epics: false)

      expect(resolve_ancestors(base_epic, args)).to be_empty
    end

    it 'does not return ancestor epics when user has no access to group epics' do
      expect(resolve_ancestors(base_epic, args)).to be_empty
    end

    context 'when user has access to the group epics' do
      before do
        group.add_developer(current_user)
      end

      it 'returns non confidential ancestor epics' do
        expect(resolve_ancestors(base_epic, args)).to contain_exactly(epic1, epic2)
      end

      it 'returns confidential ancestors' do
        expect(resolve_ancestors(confidential_epic, args))
          .to contain_exactly(confidential_epic1, confidential_epic2)
      end

      context 'with subgroups' do
        let_it_be(:sub_group) { create(:group, :private, parent: group) }
        let_it_be(:epic3)    { create(:epic, group: sub_group, parent: epic2) }
        let_it_be(:epic4)    { create(:epic, group: sub_group, parent: epic3) }

        before do
          sub_group.add_developer(current_user)
        end

        it 'returns all ancestors in the correct order' do
          expect(resolve_ancestors(epic4, args)).to eq([epic1, epic2, epic3])
        end

        it 'does not return parent group epics when include_ancestor_groups is false' do
          expect(resolve_ancestors(epic4, { include_ancestor_groups: false }))
            .to contain_exactly(epic3)
        end
      end
    end

    context 'when user is a guest' do
      before do
        group.add_guest(current_user)
      end

      it 'returns non confidential ancestor epics' do
        expect(resolve_ancestors(base_epic, args)).to contain_exactly(epic1, epic2)
      end

      it 'does not return confidential epics' do
        expect(resolve_ancestors(confidential_epic, args)).to be_empty
      end
    end
  end

  def resolve_ancestors(object, args = {}, context = { current_user: current_user })
    resolve(described_class, obj: object, args: args, ctx: context)
  end
end
