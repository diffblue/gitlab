# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Settings::MergeRequestsController, feature_category: :code_review_workflow do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'PATCH #update' do
    subject do
      patch group_settings_merge_requests_path(group), params: {
        group_id: group,
        namespace_setting: {
          only_allow_merge_if_pipeline_succeeds: true,
          allow_merge_on_skipped_pipeline: true,
          only_allow_merge_if_all_discussions_are_resolved: true
        }
      }
    end

    context 'when user is not an admin' do
      before do
        group.add_owner(user)
      end

      it 'respond status :not_found' do
        subject
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is an admin' do
      let(:user) { create(:admin) }

      before do
        stub_licensed_features(group_level_merge_checks_setting: true)
        group.add_owner(user)
      end

      it { is_expected.to redirect_to(edit_group_path(group, anchor: 'js-merge-requests-settings')) }

      context 'when service execution went wrong' do
        let(:update_service) { double }

        before do
          allow_next_instance_of(Groups::UpdateService) do |service|
            allow(service).to receive(:execute).and_return(false)
          end
          subject
        end

        it 'returns a flash alert' do
          expect(flash[:alert]).to eq("Group '#{group.name}' could not be updated.")
        end
      end

      context 'when service execution was successful' do
        it 'returns a flash notice' do
          subject

          expect(flash[:notice]).to eq("Group '#{group.name}' was successfully updated.")
          expect(group.namespace_settings.reload).to have_attributes(
            only_allow_merge_if_pipeline_succeeds: true,
            allow_merge_on_skipped_pipeline: true,
            only_allow_merge_if_all_discussions_are_resolved: true
          )
        end
      end
    end
  end
end
