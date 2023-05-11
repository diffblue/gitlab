# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MemberRole, feature_category: :system_access do
  describe 'associations' do
    it { is_expected.to belong_to(:namespace) }
    it { is_expected.to have_many(:members) }
  end

  describe 'validation' do
    subject(:member_role) { build(:member_role) }

    it { is_expected.to validate_presence_of(:namespace) }
    it { is_expected.to validate_presence_of(:base_access_level) }

    context 'for attributes_locked_after_member_associated' do
      context 'when assigned to member' do
        it 'cannot be changed' do
          member_role.save!
          member_role.members << create(:project_member)

          expect(member_role).not_to be_valid
          expect(member_role.errors.messages[:base]).to include(s_(
            "MemberRole|cannot be changed because it is already assigned to a user. " \
            "Please create a new Member Role instead"
          ))
        end
      end

      context 'when not assigned to member' do
        it 'can be changed' do
          expect(member_role).to be_valid
        end
      end
    end

    context 'for max_count_per_group_hierarchy' do
      let_it_be(:group) { create(:group) }

      subject(:member_role) { build(:member_role, namespace: group) }

      context 'when number of member roles is below limit' do
        it 'is valid' do
          is_expected.to be_valid
        end
      end

      context 'when number of member roles is above limit' do
        before do
          stub_const('MemberRole::MAX_COUNT_PER_GROUP_HIERARCHY', 1)
          create(:member_role, namespace: group)
          group.reload
        end

        it 'is invalid' do
          is_expected.to be_invalid
        end
      end
    end

    context 'when for namespace' do
      let_it_be(:root_group) { create(:group) }

      context 'when namespace is a subgroup' do
        it 'is invalid' do
          subgroup = create(:group, parent: root_group)
          member_role.namespace = subgroup

          expect(member_role).to be_invalid
          expect(member_role.errors[:namespace]).to include(
            s_("MemberRole|must be top-level namespace")
          )
        end
      end

      context 'when namespace is a root group' do
        it 'is valid' do
          member_role.namespace = root_group

          expect(member_role).to be_valid
        end
      end

      context 'when namespace is not present' do
        it 'is invalid with a different error message' do
          member_role.namespace = nil

          expect(member_role).to be_invalid
          expect(member_role.errors[:namespace]).to include(_("can't be blank"))
        end
      end

      context 'when namespace is outside hierarchy of member' do
        it 'creates a validation error' do
          member_role.save!
          member_role.namespace = create(:group)

          expect(member_role).not_to be_valid
          expect(member_role.errors[:namespace]).to include(s_("MemberRole|can't be changed"))
        end
      end
    end
  end

  describe 'callbacks' do
    context 'for preventing deletion after member is associated' do
      let_it_be(:member_role) { create(:member_role) }

      subject(:destroy_member_role) { member_role.destroy } # rubocop: disable Rails/SaveBang

      it 'allows deletion without any member associated' do
        expect(destroy_member_role).to be_truthy
      end

      it 'prevent deletion when member is associated' do
        create(:group_member, { group: member_role.namespace,
                                access_level: Gitlab::Access::DEVELOPER,
                                member_role: member_role })
        member_role.members.reload

        expect(destroy_member_role).to be_falsey
        expect(member_role.errors.messages[:base])
          .to(
            include(s_(
              "MemberRole|cannot be deleted because it is already assigned to a user. " \
              "Please disassociate the member role from all users before deletion."
            ))
          )
      end
    end
  end

  describe 'scopes' do
    describe '.elevating' do
      it 'creates proper query' do
        stub_const("#{described_class.name}::ALL_CUSTOMIZABLE_PERMISSIONS", { read_code: 'Permission to read code',
                                                                              see_code: 'Test permission' })

        expect(described_class.elevating.to_sql).to include('WHERE (see_code = true)')
      end

      it 'creates proper query with multiple permissions' do
        stub_const("#{described_class.name}::ALL_CUSTOMIZABLE_PERMISSIONS", { read_code: 'Permission to read code',
                                                                              see_code: 'Test permission',
                                                                              remove_code: 'Test second permission' })

        expect(described_class.elevating.to_sql).to include('WHERE (see_code = true OR remove_code = true)')
      end

      it 'returns nothing when there are no elevating permissions' do
        create(:member_role)

        expect(described_class.elevating).to be_empty
      end
    end
  end

  describe 'covering all permissions columns' do
    it 'has all attributes listed in the member_roles table' do
      expect(described_class.attribute_names.map(&:to_sym))
        .to contain_exactly(*described_class::ALL_CUSTOMIZABLE_PERMISSIONS.keys,
          *described_class::NON_PERMISSION_COLUMNS)
    end
  end
end
