# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::DeregisterSuggestedReviewersProjectService, :saas, feature_category: :code_review_workflow do
  include AfterNextHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  subject(:service) { described_class.new(project: project, current_user: user) }

  describe '#execute' do
    let(:deregistration_result) do
      {
        project_id: project.project_id,
        deregistered_at: '2022-01-01 01:01'
      }
    end

    let(:deregistration_input) do
      {
        project_id: project.project_id
      }
    end

    subject(:result) { service.execute }

    shared_examples 'an unavailable response' do
      it 'returns an error response without calling client', :aggregate_failures do
        expect(Gitlab::AppliedMl::SuggestedReviewers::Client).not_to receive(:new)

        expect(result).to be_a(ServiceResponse)
        expect(result).to be_error
        expect(result.message).to eq('Suggested Reviewers deregistration is unavailable')
        expect(result.reason).to eq(:feature_unavailable)
      end
    end

    before do
      project.add_maintainer(user)
    end

    context 'when the suggested reviewers is not available' do
      before do
        allow(project).to receive(:suggested_reviewers_available?).and_return(false)
      end

      it_behaves_like 'an unavailable response'
    end

    context 'when the suggested reviewers is available' do
      before do
        allow(project).to receive(:suggested_reviewers_available?).and_return(true)
      end

      context 'when the suggested reviewers is enabled' do
        before do
          allow(project).to receive(:suggested_reviewers_enabled).and_return(true)
        end

        it_behaves_like 'an unavailable response'
      end

      context 'when the suggested reviewers is not enabled' do
        before do
          stub_env('SUGGESTED_REVIEWERS_SECRET', SecureRandom.hex(32))
          allow(project).to receive(:suggested_reviewers_enabled).and_return(false)
        end

        context 'when project is not found' do
          it 'returns an error response', :aggregate_failures do
            allow_next(Gitlab::AppliedMl::SuggestedReviewers::Client)
              .to receive(:deregister_project)
              .with(deregistration_input)
              .and_raise(Gitlab::AppliedMl::Errors::ProjectNotFound)

            expect(result).to be_a(ServiceResponse)
            expect(result).to be_error
            expect(result.message).to eq('Project is not found')
            expect(result.reason).to eq(:project_not_found)
          end
        end

        context 'when suggested reviewers client fails' do
          it 'returns an error response', :aggregate_failures do
            allow_next(Gitlab::AppliedMl::SuggestedReviewers::Client)
              .to receive(:deregister_project)
              .with(deregistration_input)
              .and_raise(Gitlab::AppliedMl::Errors::ResourceNotAvailable)

            expect(result).to be_a(ServiceResponse)
            expect(result).to be_error
            expect(result.message).to eq('Failed to deregister project')
            expect(result.reason).to eq(:client_request_failed)
          end
        end

        context 'when suggested reviewers client succeeds' do
          it 'returns a success response', :aggregate_failures do
            allow_next(Gitlab::AppliedMl::SuggestedReviewers::Client)
              .to receive(:deregister_project)
              .with(hash_including(deregistration_input))
              .and_return(deregistration_result)

            expect(result).to be_a(ServiceResponse)
            expect(result).to be_success
            expect(result.payload).to eq(deregistration_result)
          end
        end
      end
    end
  end
end
