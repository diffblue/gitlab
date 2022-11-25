# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestSidebarBasicEntity do
  let(:project) { create :project, :repository }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:user) { create(:user) }

  let(:request) { double('request', current_user: user, project: project) }

  let(:entity) { described_class.new(merge_request, request: request).as_json }

  describe '#current_user' do
    context 'when the gitlab_employee_badge flag is off' do
      it 'does not expose the is_gitlab_employee field for the current user' do
        stub_feature_flags(gitlab_employee_badge: false)

        expect(entity[:current_user].keys).to contain_exactly(
          :id, :name, :username, :state, :avatar_url, :web_url, :todo, :can_create_timelogs,
          :can_edit, :can_move, :can_admin_label, :can_merge, :can_update_merge_request
        )
      end
    end

    context 'when the gitlab_employee_badge flag is on but we are not on gitlab.com' do
      it 'does not expose the is_gitlab_employee field for the current user' do
        stub_feature_flags(gitlab_employee_badge: true)
        allow(Gitlab).to receive(:com?).and_return(false)

        expect(entity[:current_user].keys).to contain_exactly(
          :id, :name, :username, :state, :avatar_url, :web_url, :todo, :can_create_timelogs,
          :can_edit, :can_move, :can_admin_label, :can_merge, :can_update_merge_request
        )
      end
    end

    context 'when the gitlab_employee_badge flag is on and we are on gitlab.com' do
      it 'exposes the is_gitlab_employee field for the current user' do
        stub_feature_flags(gitlab_employee_badge: true)
        allow(Gitlab).to receive(:com?).and_return(true)

        expect(entity[:current_user].keys).to contain_exactly(
          :id, :name, :username, :state, :avatar_url, :web_url, :todo, :can_create_timelogs,
          :can_edit, :can_move, :can_admin_label, :can_merge, :is_gitlab_employee, :can_update_merge_request
        )
      end
    end
  end
end
