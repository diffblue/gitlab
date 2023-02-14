# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MemberPresenter, feature_category: :subgroups do
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:group) { build_stubbed(:group) }
  let_it_be(:member) { build_stubbed(:group_member, :guest, source: group, user: user) }
  let(:presenter) { described_class.new(member, current_user: user) }

  describe '#human_access' do
    context 'when user has static role' do
      it 'returns human name for access level' do
        access_levels = {
          "Guest" => Gitlab::Access::GUEST,
          "Reporter" => Gitlab::Access::REPORTER,
          "Developer" => Gitlab::Access::DEVELOPER,
          "Maintainer" => Gitlab::Access::MAINTAINER,
          "Owner" => Gitlab::Access::OWNER
        }

        access_levels.each do |human_name, access_level|
          member.access_level = access_level
          expect(presenter.human_access).to eq human_name
        end
      end

      context 'when user has a custom role' do
        it 'returns custom roles' do
          member_role = build_stubbed(:member_role, :guest, namespace: group)
          member.member_role = member_role
          member.access_level = Gitlab::Access::GUEST

          expect(presenter.human_access).to eq format(s_("MemberRole|%{role} - custom"), role: "Guest")
        end
      end
    end
  end
end
