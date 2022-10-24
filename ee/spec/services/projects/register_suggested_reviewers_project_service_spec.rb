# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::RegisterSuggestedReviewersProjectService, :saas do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  subject(:service) { described_class.new(project: project, current_user: user).execute }

  describe '#execute' do
    let(:registration_result) do
      {
        project_id: project.project_id,
        registered_at: '2022-01-01 01:01'
      }
    end

    let(:success_result) do
      registration_result.merge({ status: :success })
    end

    let(:registration_input) do
      {
        project_id: project.project_id,
        project_name: project.name,
        project_namespace: project.namespace.full_path
      }
    end

    shared_examples 'not calling suggested reviewers client' do
      it 'returns nil without calling client' do
        expect(Gitlab::AppliedMl::SuggestedReviewers::Client).not_to receive(:new)
        expect(service).to eq(nil)
      end
    end

    before do
      project.add_maintainer(user)
    end

    context 'when the suggested reviewers is not available' do
      before do
        allow(project).to receive(:suggested_reviewers_available?).and_return(false)
      end

      it_behaves_like 'not calling suggested reviewers client'
    end

    context 'when the suggested reviewers is available' do
      before do
        allow(project).to receive(:suggested_reviewers_available?).and_return(true)
      end

      context 'when the suggested reviewers is not enabled' do
        before do
          allow(project).to receive(:suggested_reviewers_enabled).and_return(false)
        end

        it_behaves_like 'not calling suggested reviewers client'
      end

      context 'when the suggested reviewers is enabled' do
        before do
          stub_env('SUGGESTED_REVIEWERS_SECRET', SecureRandom.hex(32))
          allow(project).to receive(:suggested_reviewers_enabled).and_return(true)
        end

        context 'when the user cannot create access tokens' do
          before do
            project.add_developer(user)
          end

          it_behaves_like 'not calling suggested reviewers client'
        end

        context 'when the user can create access tokens' do
          before do
            project.add_maintainer(user)
          end

          it 'creates an access token', :aggregate_failures do
            freeze_time do
              token_params = {
                name: 'Suggested reviewers token',
                scopes: [Gitlab::Auth::READ_API_SCOPE],
                expires_at: 95.days.from_now
              }

              allow_next_instance_of(Gitlab::AppliedMl::SuggestedReviewers::Client) do |client|
                allow(client).to receive(:register_project)
                                   .with(hash_including(registration_input))
                                   .and_return(registration_result)
              end

              expect_next_instance_of(
                ResourceAccessTokens::CreateService, user, project, token_params
              ) do |token_service|
                expect(token_service).to receive(:execute).and_call_original
              end
              expect(service[:status]).to eq(:success)
            end
          end

          it 'returns success and calls suggested reviewers client', :aggregate_failures do
            expect_next_instance_of(Gitlab::AppliedMl::SuggestedReviewers::Client) do |client|
              expect(client).to receive(:register_project)
                                  .with(hash_including(registration_input))
                                  .and_return(registration_result)
            end

            expect(service[:status]).to eq(:success)
          end
        end
      end
    end
  end
end
