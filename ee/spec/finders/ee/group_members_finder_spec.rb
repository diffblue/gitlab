# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupMembersFinder do
  subject(:finder) { described_class.new(group) }

  let_it_be(:group) { create :group }

  let_it_be(:non_owner_access_level) { Gitlab::Access.options.values.sample }
  let_it_be(:group_owner_membership) { group.add_member(create(:user), Gitlab::Access::OWNER) }
  let_it_be(:group_member_membership) { group.add_member(create(:user), non_owner_access_level) }
  let_it_be(:dedicated_member_account_membership) do
    group.add_member(create(:user, managing_group: group), non_owner_access_level)
  end

  describe '#not_managed' do
    it 'returns non-owners without group managed accounts' do
      expect(finder.not_managed).to eq([group_member_membership])
    end
  end

  describe '#execute' do
    context 'minimal access' do
      let_it_be(:group_minimal_access_membership) do
        create(:group_member, :minimal_access, source: group)
      end

      context 'when group does not allow minimal access members' do
        before do
          stub_licensed_features(minimal_access_role: false)
        end

        it 'returns only members with full access' do
          result = finder.execute(include_relations: [:direct, :descendants])

          expect(result.to_a).to match_array([group_owner_membership, group_member_membership, dedicated_member_account_membership])
        end
      end

      context 'when group allows minimal access members' do
        before do
          stub_licensed_features(minimal_access_role: true)
        end

        it 'also returns members with minimal access' do
          result = finder.execute(include_relations: [:direct, :descendants])

          expect(result.to_a).to match_array([group_owner_membership, group_member_membership, dedicated_member_account_membership, group_minimal_access_membership])
        end
      end
    end

    context 'filter by enterprise users' do
      let_it_be(:saml_provider) { create(:saml_provider, group: group) }
      let_it_be(:enterprise_member_1_of_root_group) { group.add_developer(create(:user, provisioned_by_group_id: group.id)) }
      let_it_be(:enterprise_member_2_of_root_group) { group.add_developer(create(:user, provisioned_by_group_id: group.id)) }

      let(:all_members) do
        [
          group_owner_membership,
          group_member_membership,
          dedicated_member_account_membership,
          enterprise_member_1_of_root_group,
          enterprise_member_2_of_root_group
        ]
      end

      context 'the group has SAML enabled' do
        context 'when requested by owner' do
          let(:current_user) { group_owner_membership.user }

          context 'direct members of the group' do
            it 'returns Enterprise members when the filter is `true`' do
              result = described_class.new(group, current_user, params: { enterprise: 'true' }).execute

              expect(result.to_a).to match_array([enterprise_member_1_of_root_group, enterprise_member_2_of_root_group])
            end

            it 'returns members that are not Enterprise members when the filter is `false`' do
              result = described_class.new(group, current_user, params: { enterprise: 'false' }).execute

              expect(result.to_a).to match_array([group_owner_membership, group_member_membership, dedicated_member_account_membership])
            end

            it 'returns all members when the filter is not specified' do
              result = described_class.new(group, current_user, params: {}).execute

              expect(result.to_a).to match_array(all_members)
            end

            it 'returns all members when the filter is not either of `true` or `false`' do
              result = described_class.new(group, current_user, params: { enterprise: 'not-valid' }).execute

              expect(result.to_a).to match_array(all_members)
            end
          end

          context 'inherited members of the group' do
            let_it_be(:subgroup) { create(:group, parent: group) }
            let_it_be(:subgroup_member_membership) { subgroup.add_developer(create(:user)) }

            it 'returns all members including inherited members, that are Enterprise members, when the filter is `true`' do
              result = described_class.new(subgroup, current_user, params: { enterprise: 'true' }).execute

              expect(result.to_a).to match_array([enterprise_member_1_of_root_group, enterprise_member_2_of_root_group])
            end

            it 'returns all members including inherited members, that are not Enterprise members, when the filter is `false`' do
              result = described_class.new(subgroup, current_user, params: { enterprise: 'false' }).execute

              expect(result.to_a).to match_array(
                [
                  group_owner_membership,
                  group_member_membership,
                  dedicated_member_account_membership,
                  subgroup_member_membership
                ]
              )
            end
          end
        end

        context 'when requested by non-owner' do
          let(:current_user) { group_member_membership.user }

          it 'returns all members, as non-owners do not have the ability to filter by Enterprise users' do
            result = described_class.new(group, current_user, params: { enterprise: 'true' }).execute

            expect(result.to_a).to match_array(all_members)
          end
        end
      end

      context 'the group does not have SAML enabled' do
        before do
          group.saml_provider.destroy!
        end

        context 'when requested by owner' do
          let(:current_user) { group_owner_membership.user }

          it 'returns all members, because `Enterprise` filter can only be applied on groups that have SAML enabled' do
            result = described_class.new(group, current_user, params: { enterprise: 'true' }).execute

            expect(result.to_a).to match_array(all_members)
          end
        end
      end
    end
  end
end
