# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExternalStatusChecks::RetryService, feature_category: :groups_and_projects do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:rule) { create(:external_status_check, project: project) }
  let_it_be(:merge_request) do
    create(:merge_request, source_branch: 'feature', target_branch: 'master', source_project: project)
  end

  let!(:status_check_response) do
    create(:status_check_response,
      external_status_check: rule,
      merge_request: merge_request,
      sha: merge_request.diff_head_sha,
      status: status)
  end

  subject do
    described_class.new(
      container: project,
      current_user: user,
      params: { merge_request: merge_request }
    ).execute(rule)
  end

  context 'when user has permissions' do
    let(:user) { project.first_owner }

    context 'when licensed feature `external_status_checks` is available' do
      before do
        stub_licensed_features(external_status_checks: true)
      end

      context 'when status check response status is `failed`' do
        let(:status) { 'failed' }

        context 'when rule retry operation suceeds' do
          let(:data) { merge_request.to_hook_data(user) }

          it 'updates `retried_at` field for the last status check response and async executes with data' do
            expect_any_instance_of(::MergeRequests::ExternalStatusCheck).to receive(:async_execute).with(data) # rubocop:disable RSpec/AnyInstanceOf - It's not the next instance

            subject

            expect(subject.success?).to be true

            status_check_response.reload

            expect(status_check_response.status).to be('failed')
            expect(status_check_response.retried_at).not_to be_nil
          end
        end

        context 'when rule retry operation fails' do
          before do
            allow_any_instance_of(::MergeRequests::StatusCheckResponse).to receive(:update).and_return(false) # rubocop:disable RSpec/AnyInstanceOf - It's not the next instance
          end

          it 'does not update and has an appropriate error' do
            subject

            expect(subject.error?).to be true
            expect(subject.reason).to be :unprocessable_entity
            expect(subject.message).to be('Failed to retry rule')

            status_check_response.reload

            expect(status_check_response.retried_at).to be_nil
          end
        end
      end

      context 'when status check response status is not `failed`' do
        let(:status) { 'passed' }

        it 'contains an appropriate response' do
          expect(subject.error?).to be true
          expect(subject.reason).to eq(:unprocessable_entity)
          expect(subject.message).to eq('Failed to retry rule')
          expect(subject.payload[:errors]).to eq('External status check must be failed')
        end
      end
    end
  end

  context 'when user does not have permissions' do
    let_it_be(:user) { create(:user) }
    let(:status) { 'failed' }

    before do
      project.add_guest(user)
    end

    it 'returns an unauthorized response' do
      expect(subject.reason).to eq(:unauthorized)
      expect(subject.message).to eq('Failed to retry rule')
      expect(subject.payload[:errors]).to eq('Not allowed')
    end
  end
end
