# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::MemberRolePolicy, feature_category: :system_access do
  let_it_be(:member_role) { create(:member_role) }
  let_it_be(:group) { member_role.namespace }
  let_it_be(:user) { create(:user) }

  subject(:policy) { described_class.new(user, member_role) }

  describe 'rules' do
    context 'without the custom roles feature' do
      before do
        stub_licensed_features(custom_roles: false)
      end

      context 'when owner' do
        before_all do
          group.add_owner(user)
        end

        it { is_expected.to be_disallowed(:admin_group_member) }
      end
    end

    context 'with the custom roles feature' do
      before do
        stub_licensed_features(custom_roles: true)
      end

      it { is_expected.to be_disallowed(:admin_group_member) }

      context 'when maintainer' do
        before_all do
          group.add_maintainer(user)
        end

        it { is_expected.to be_disallowed(:admin_group_member) }
      end

      context 'when owner' do
        before_all do
          group.add_owner(user)
        end

        it { is_expected.to be_allowed(:admin_group_member) }
      end
    end
  end
end
