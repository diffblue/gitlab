# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::UpdateHighestMemberRoleService, feature_category: :user_management do
  let_it_be(:user) { create(:user) }

  subject(:execute_service) { described_class.new(user).execute }

  describe '#execute' do
    context 'with an EE-only access level' do
      before do
        allow(user).to receive(:current_highest_access_level).and_return(Gitlab::Access::MINIMAL_ACCESS)
      end

      it 'updates the highest access level' do
        user_highest_role = create(:user_highest_role, :guest, user: user)

        expect { execute_service }
          .to change { user_highest_role.reload.highest_access_level }
          .from(Gitlab::Access::GUEST)
          .to(Gitlab::Access::MINIMAL_ACCESS)
      end
    end
  end
end
