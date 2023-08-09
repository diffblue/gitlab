# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Preloaders::UserMemberRolesInGroupsPreloader, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:root_group) { create(:group, :private) }
  let_it_be(:group) { create(:group, :private, parent: root_group) }
  let_it_be(:group_member) { create(:group_member, :guest, user: user, source: group) }

  let(:group_list) { [group] }

  subject(:result) { described_class.new(groups: group_list, user: user).execute }

  def ability_requirement(ability)
    ability_definition = MemberRole::ALL_CUSTOMIZABLE_PERMISSIONS[ability]
    ability_definition[:requirement]
  end

  def create_member_role(ability, member)
    create(:member_role, :guest, namespace: root_group).tap do |record|
      record[ability] = true
      record[ability_requirement(ability)] = true if ability_requirement(ability)
      record.save!
      record.members << member
    end
  end

  shared_examples 'custom roles' do |ability|
    let(:expected_abilities) { [ability, ability_requirement(ability)].compact }

    context 'when custom_roles license is not enabled on group root ancestor' do
      it 'skips preload' do
        stub_licensed_features(custom_roles: false)
        create_member_role(ability, group_member)

        expect(result).to eq({})
      end
    end

    context 'when custom_roles license is enabled on group root ancestor' do
      before do
        stub_licensed_features(custom_roles: true)
      end

      context 'when group has custom role' do
        let_it_be(:member_role) do
          create_member_role(ability, group_member)
        end

        context 'when custom role has ability: true' do
          let(:group_list) { Group.where(id: group.id) }

          it 'returns the group_id with a value array that includes the ability' do
            expect(result[group.id]).to match_array(expected_abilities)
          end
        end
      end

      context 'when user is a member of the group in multiple ways' do
        let_it_be(:root_group_member) do
          create(:group_member, :guest, user: user, source: root_group)
        end

        it 'group value array includes the ability' do
          create_member_role(ability, group_member)
          create(:member_role, :guest, namespace: root_group).tap do |record|
            record[ability] = false
            record.save!
            record.members << root_group_member
          end

          expect(result[group.id]).to match_array(expected_abilities)
        end
      end

      context 'when group membership has no custom role' do
        let_it_be(:group) { create(:group, :private) }

        it 'returns group id with empty value array' do
          expect(result).to eq(group.id => [])
        end
      end

      context 'when group membership has custom role that does not enable custom permission' do
        let_it_be(:group) { create(:group, :private) }

        it 'returns group id with empty value array' do
          group_without_custom_permission_member = create(
            :group_member,
            :guest,
            user: user,
            source: group
          )
          create(:member_role, :guest, namespace: root_group).tap do |record|
            record[ability] = false
            record.save!
            record.members << group_without_custom_permission_member
          end

          expect(result).to eq(group.id => [])
        end
      end

      context 'when user has custom role that enables custom permission outside of group hierarchy' do
        it 'ignores custom role outside of group hierarchy' do
          # subgroup is within parent group of group but not above group
          subgroup = create(:group, :private, parent: root_group)
          subgroup_member = create(:group_member, :guest, user: user, source: subgroup)
          create_member_role(ability, subgroup_member)

          expect(result).to eq({ group.id => [] })
        end
      end
    end
  end

  it_behaves_like 'custom roles', :read_vulnerability
  it_behaves_like 'custom roles', :admin_vulnerability
end
