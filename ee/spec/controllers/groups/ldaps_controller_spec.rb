# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::LdapsController, feature_category: :system_access do
  include LdapHelpers

  let(:group) { create(:group) }
  let(:user)  { create(:user) }

  before do
    stub_ldap_setting(enabled: true)
    group.add_owner(user)

    sign_in(user)
  end

  describe 'POST #sync' do
    subject do
      Sidekiq::Testing.fake! do
        post :sync, params: { group_id: group.to_param }
      end
    end

    it 'transitions to the pending state' do
      subject

      expect(group.reload.ldap_sync_pending?).to be_truthy

      expect(controller).to redirect_to(group_group_members_path(group))
    end

    it 'notifies user that the group is already pending' do
      group.update_columns(ldap_sync_status: 'pending')

      subject

      expect(flash[:notice]).to eq('The group sync is already scheduled')
      expect(controller).to redirect_to(group_group_members_path(group))
    end

    it 'returns an error if the group does not validate' do
      group.update_columns(repository_size_limit: -1)

      expect(group).not_to be_valid

      subject

      expect(flash[:alert]).to include('This group is in an invalid state')
      expect(controller).to redirect_to(group_group_members_path(group))
    end
  end
end
