# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::RegisterSuggestedReviewersProjectService, :saas, feature_category: :workflow_automation do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  subject(:service) { described_class.new(project: project, current_user: user) }

  describe '#execute' do
    let(:registration_result) do
      {
        project_id: project.project_id,
        registered_at: '2022-01-01 01:01'
      }
    end

    let(:registration_input) do
      {
        project_id: project.project_id,
        project_name: project.name,
        project_namespace: project.namespace.full_path,
        access_token: a_kind_of(String)
      }
    end

    subject(:result) { service.execute }

    shared_examples 'an unavailable response' do
      it 'returns an error response without calling client', :aggregate_failures do
        expect(ResourceAccessTokens::CreateService).not_to receive(:new)
        expect(Gitlab::AppliedMl::SuggestedReviewers::Client).not_to receive(:new)

        expect(result).to be_a(ServiceResponse)
        expect(result).to be_error
        expect(result.message).to eq('Suggested Reviewers feature is unavailable')
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

      context 'when the suggested reviewers is not enabled' do
        before do
          allow(project).to receive(:suggested_reviewers_enabled).and_return(false)
        end

        it_behaves_like 'an unavailable response'
      end

      context 'when the suggested reviewers is enabled' do
        before do
          stub_env('SUGGESTED_REVIEWERS_SECRET', SecureRandom.hex(32))
          allow(project).to receive(:suggested_reviewers_enabled).and_return(true)

          allow_next_instance_of(ResourceAccessTokens::CreateService, user, project, anything) do |token_service|
            allow(token_service).to receive(:execute).and_return(token_response)
          end
        end

        context 'when the user cannot create access tokens' do
          before do
            project.add_developer(user)
          end

          it_behaves_like 'an unavailable response'
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

              expect_next_instance_of(
                ResourceAccessTokens::CreateService, user, project, token_params
              ) do |token_service|
                expect(token_service).to receive(:execute).and_call_original
              end

              expect_next_instance_of(Gitlab::AppliedMl::SuggestedReviewers::Client) do |client|
                expect(client).to receive(:register_project)
                                    .with(registration_input)
                                    .and_return(registration_result)
              end

              result
            end
          end

          context 'when token creation succeeds', :aggregate_failures do
            let(:token_response) do
              ServiceResponse.success(payload: { access_token: build(:personal_access_token) })
            end

            context 'when suggested reviewers client succeeds' do
              it 'returns a success response', :aggregate_failures do
                allow_next_instance_of(Gitlab::AppliedMl::SuggestedReviewers::Client) do |client|
                  allow(client).to receive(:register_project)
                                     .with(hash_including(registration_input))
                                     .and_return(registration_result)
                end

                expect(result).to be_a(ServiceResponse)
                expect(result).to be_success
                expect(result.payload).to eq(registration_result)
              end
            end

            context 'when suggested reviewers client fails' do
              it 'returns an error response', :aggregate_failures do
                allow_next_instance_of(Gitlab::AppliedMl::SuggestedReviewers::Client) do |client|
                  allow(client).to receive(:register_project)
                                     .with(registration_input)
                                     .and_raise(Gitlab::AppliedMl::Errors::ResourceNotAvailable)
                end

                expect(result).to be_a(ServiceResponse)
                expect(result).to be_error
                expect(result.message).to eq('Failed to register project')
                expect(result.reason).to eq(:client_request_failed)
              end
            end

            context 'when project is already registered', :aggregate_failures do
              it 'returns an error response', :aggregate_failures do
                allow_next_instance_of(Gitlab::AppliedMl::SuggestedReviewers::Client) do |client|
                  allow(client).to receive(:register_project)
                                     .with(registration_input)
                                     .and_raise(Gitlab::AppliedMl::Errors::ProjectAlreadyExists)
                end

                expect(result).to be_a(ServiceResponse)
                expect(result).to be_error
                expect(result.message).to eq('Project is already registered')
                expect(result.reason).to eq(:project_already_registered)
              end
            end
          end

          context 'when token creation fails', :aggregate_failures do
            let(:token_response) { ServiceResponse.error(message: 'No joy') }

            it 'returns an error response and does not call suggested reviewers client', :aggregate_failures do
              expect(Gitlab::AppliedMl::SuggestedReviewers::Client).not_to receive(:new)

              expect(result).to be_a(ServiceResponse)
              expect(result).to be_error
              expect(result.message).to eq('Failed to create access token')
              expect(result.reason).to eq(:token_creation_failed)
            end
          end
        end
      end
    end
  end
end
