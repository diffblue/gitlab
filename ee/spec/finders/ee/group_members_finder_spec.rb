# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupMembersFinder, feature_category: :groups_and_projects do
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
    context 'with custom roles' do
      let_it_be(:group)                { create(:group) }
      let_it_be(:sub_group)            { create(:group, parent: group) }
      let_it_be(:sub_sub_group)        { create(:group, parent: sub_group) }
      let_it_be(:public_shared_group)  { create(:group, :public) }
      let_it_be(:private_shared_group) { create(:group, :private) }
      let_it_be(:user1)                { create(:user) }
      let_it_be(:user2)                { create(:user) }
      let_it_be(:user3)                { create(:user) }
      let_it_be(:user4)                { create(:user) }
      let_it_be(:user5_2fa)            { create(:user, :two_factor_via_otp) }

      let_it_be(:link) do
        create(:group_group_link, shared_group: group,     shared_with_group: public_shared_group)
        create(:group_group_link, shared_group: sub_group, shared_with_group: private_shared_group)
      end

      let(:groups) do
        {
          group: group,
          sub_group: sub_group,
          sub_sub_group: sub_sub_group,
          public_shared_group: public_shared_group,
          private_shared_group: private_shared_group
        }
      end

      let_it_be(:members) do
        group_custom_maintainer_role = create(:member_role, { name: 'custom maintainer',
                                                              namespace: group,
                                                              base_access_level: ::Gitlab::Access::MAINTAINER })
        group_custom_developer_role = create(:member_role, { name: 'custom developer',
                                                             namespace: group,
                                                             base_access_level: ::Gitlab::Access::DEVELOPER })
        group_custom_reporter_role = create(:member_role, { name: 'custom reporter',
                                                            namespace: group,
                                                            base_access_level: ::Gitlab::Access::REPORTER })
        public_shared_group_custom_maintainer_role = create(:member_role, { name: 'custom maintainer',
                                                                            namespace: public_shared_group,
                                                                            base_access_level: ::Gitlab::Access::MAINTAINER })
        public_shared_group_custom_developer_role = create(:member_role, { name: 'custom developer',
                                                                           namespace: public_shared_group,
                                                                           base_access_level: ::Gitlab::Access::DEVELOPER })
        public_shared_group_custom_reporter_role = create(:member_role, { name: 'custom reporter',
                                                                          namespace: public_shared_group,
                                                                          base_access_level: ::Gitlab::Access::REPORTER })
        private_shared_group_custom_maintainer_role = create(:member_role, { name: 'custom maintainer',
                                                                             namespace: private_shared_group,
                                                                             base_access_level: ::Gitlab::Access::MAINTAINER })
        private_shared_group_custom_developer_role = create(:member_role, { name: 'custom developer',
                                                                            namespace: private_shared_group,
                                                                            base_access_level: ::Gitlab::Access::DEVELOPER })
        private_shared_group_custom_reporter_role = create(:member_role, { name: 'custom reporter',
                                                                           namespace: private_shared_group,
                                                                           base_access_level: ::Gitlab::Access::REPORTER })
        {
          user1_sub_sub_group: create(:group_member, :maintainer, group: sub_sub_group, user: user1, member_role: group_custom_maintainer_role),
          user1_sub_group: create(:group_member, :developer, group: sub_group, user: user1, member_role: group_custom_developer_role),
          user1_group: create(:group_member, :reporter, group: group, user: user1, member_role: group_custom_reporter_role),
          user1_public_shared_group: create(:group_member, :maintainer, group: public_shared_group, user: user1, member_role: public_shared_group_custom_maintainer_role),
          user1_private_shared_group: create(:group_member, :maintainer, group: private_shared_group, user: user1, member_role: private_shared_group_custom_maintainer_role),
          user2_sub_sub_group: create(:group_member, :reporter, group: sub_sub_group, user: user2, member_role: group_custom_reporter_role),
          user2_sub_group: create(:group_member, :developer, group: sub_group, user: user2, member_role: group_custom_developer_role),
          user2_group: create(:group_member, :maintainer, group: group, user: user2, member_role: group_custom_maintainer_role),
          user2_public_shared_group: create(:group_member, :developer, group: public_shared_group, user: user2, member_role: public_shared_group_custom_developer_role),
          user2_private_shared_group: create(:group_member, :developer, group: private_shared_group, user: user2, member_role: private_shared_group_custom_developer_role),
          user3_sub_sub_group: create(:group_member, :developer, group: sub_sub_group, user: user3, expires_at: 1.day.from_now, member_role: group_custom_developer_role),
          user3_sub_group: create(:group_member, :developer, group: sub_group, user: user3, expires_at: 2.days.from_now, member_role: group_custom_developer_role),
          user3_group: create(:group_member, :reporter, group: group, user: user3, member_role: group_custom_reporter_role),
          user3_public_shared_group: create(:group_member, :reporter, group: public_shared_group, user: user3, member_role: public_shared_group_custom_reporter_role),
          user3_private_shared_group: create(:group_member, :reporter, group: private_shared_group, user: user3, member_role: private_shared_group_custom_reporter_role),
          user4_sub_sub_group: create(:group_member, :reporter, group: sub_sub_group, user: user4, member_role: group_custom_reporter_role),
          user4_sub_group: create(:group_member, :developer, group: sub_group, user: user4, expires_at: 1.day.from_now, member_role: group_custom_developer_role),
          user4_group: create(:group_member, :developer, group: group, user: user4, expires_at: 2.days.from_now, member_role: group_custom_developer_role),
          user4_public_shared_group: create(:group_member, :developer, group: public_shared_group, user: user4, member_role: public_shared_group_custom_developer_role),
          user4_private_shared_group: create(:group_member, :developer, group: private_shared_group, user: user4, member_role: private_shared_group_custom_developer_role),
          user5_private_shared_group: create(:group_member, :developer, group: private_shared_group, user: user5_2fa, member_role: private_shared_group_custom_developer_role)
        }
      end

      using RSpec::Parameterized::TableSyntax

      # rubocop: disable Layout/ArrayAlignment
      where(:subject_relations, :subject_group, :expected_members) do
        []                                                       | :group         | []
        GroupMembersFinder::DEFAULT_RELATIONS                    | :group         | [:user1_group, :user2_group, :user3_group, :user4_group]
        [:direct]                                                | :group         | [:user1_group, :user2_group, :user3_group, :user4_group]
        [:inherited]                                             | :group         | []
        [:descendants]                                           | :group         | [:user1_sub_group, :user1_sub_sub_group,
                                                                                     :user2_sub_group, :user2_sub_sub_group,
                                                                                     :user3_sub_group, :user3_sub_sub_group,
                                                                                     :user4_sub_group, :user4_sub_sub_group]
        [:shared_from_groups]                                    | :group         | [:user1_public_shared_group, :user2_public_shared_group, :user3_public_shared_group, :user4_public_shared_group]
        [:direct, :inherited, :descendants, :shared_from_groups] | :group         | [:user1_group, :user1_sub_group, :user1_sub_sub_group, :user1_public_shared_group,
                                                                                     :user2_group, :user2_sub_group, :user2_sub_sub_group, :user2_public_shared_group,
                                                                                     :user3_group, :user3_sub_group, :user3_sub_sub_group, :user3_public_shared_group,
                                                                                     :user4_group, :user4_sub_group, :user4_sub_sub_group, :user4_public_shared_group]
        []                                                       | :sub_group     | []
        GroupMembersFinder::DEFAULT_RELATIONS                    | :sub_group     | [:user1_group, :user1_sub_group,
                                                                                     :user2_group, :user2_sub_group,
                                                                                     :user3_group, :user3_sub_group,
                                                                                     :user4_group, :user4_sub_group]
        [:direct]                                                | :sub_group     | [:user1_sub_group, :user2_sub_group, :user3_sub_group, :user4_sub_group]
        [:inherited]                                             | :sub_group     | [:user1_group, :user2_group, :user3_group, :user4_group]
        [:descendants]                                           | :sub_group     | [:user1_sub_sub_group, :user2_sub_sub_group, :user3_sub_sub_group, :user4_sub_sub_group]
        [:shared_from_groups]                                    | :sub_group     | [:user1_public_shared_group, :user2_public_shared_group, :user3_public_shared_group, :user4_public_shared_group]
        [:direct, :inherited, :descendants, :shared_from_groups] | :sub_group     | [:user1_group, :user1_sub_group, :user1_sub_sub_group, :user1_public_shared_group,
                                                                                     :user2_group, :user2_sub_group, :user2_sub_sub_group, :user2_public_shared_group,
                                                                                     :user3_group, :user3_sub_group, :user3_sub_sub_group, :user3_public_shared_group,
                                                                                     :user4_group, :user4_sub_group, :user4_sub_sub_group, :user4_public_shared_group]
        []                                                       | :sub_sub_group | []
        GroupMembersFinder::DEFAULT_RELATIONS                    | :sub_sub_group | [:user1_group, :user1_sub_group, :user1_sub_sub_group,
                                                                                     :user2_group, :user2_sub_group, :user2_sub_sub_group,
                                                                                     :user3_group, :user3_sub_group, :user3_sub_sub_group,
                                                                                     :user4_group, :user4_sub_group, :user4_sub_sub_group]
        [:direct]                                                | :sub_sub_group | [:user1_sub_sub_group, :user2_sub_sub_group, :user3_sub_sub_group, :user4_sub_sub_group]
        [:inherited]                                             | :sub_sub_group | [:user1_group, :user1_sub_group,
                                                                                     :user2_group, :user2_sub_group,
                                                                                     :user3_group, :user3_sub_group,
                                                                                     :user4_group, :user4_sub_group]
        [:descendants]                                           | :sub_sub_group | []
        [:shared_from_groups]                                    | :sub_sub_group | [:user1_public_shared_group, :user2_public_shared_group, :user3_public_shared_group, :user4_public_shared_group]
        [:direct, :inherited, :descendants, :shared_from_groups] | :sub_sub_group | [:user1_group, :user1_sub_group, :user1_sub_sub_group, :user1_public_shared_group,
                                                                                     :user2_group, :user2_sub_group, :user2_sub_sub_group, :user2_public_shared_group,
                                                                                     :user3_group, :user3_sub_group, :user3_sub_sub_group, :user3_public_shared_group,
                                                                                     :user4_group, :user4_sub_group, :user4_sub_sub_group, :user4_public_shared_group]
      end
      # rubocop: enable Layout/ArrayAlignment
      with_them do
        it 'returns correct members' do
          result = described_class
                     .new(groups[subject_group], params: { with_custom_role: true })
                     .execute(include_relations: subject_relations)

          expect(result.to_a).to match_array(expected_members.map { |name| members[name] })
        end
      end
    end

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
