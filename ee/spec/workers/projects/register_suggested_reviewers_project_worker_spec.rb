# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::RegisterSuggestedReviewersProjectWorker, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  subject { described_class.new }

  # rubocop:disable RSpec/AnyInstanceOf
  describe '#perform' do
    context 'when project is not found' do
      it 'returns without calling the fetch suggested reviewer service' do
        expect(::Projects::RegisterSuggestedReviewersProjectService).not_to receive(:new)

        subject.perform(non_existing_record_id, user.id)
      end
    end

    context 'when project is found' do
      context 'when user is not found' do
        it 'returns without calling the fetch suggested reviewer service' do
          expect(::Projects::RegisterSuggestedReviewersProjectService).not_to receive(:new)

          subject.perform(project.id, non_existing_record_id)
        end
      end

      context 'when user is found' do
        context 'when suggested reviews is not available for the project' do
          before do
            allow_any_instance_of(::Project).to receive(:suggested_reviewers_available?).and_return(false)
          end

          it 'returns without calling the fetch suggested reviewer service', :aggregate_failures do
            expect(::Projects::RegisterSuggestedReviewersProjectService).not_to receive(:new)

            subject.perform(project.id, user.id)
          end
        end

        context 'when suggested reviews is available for the project' do
          before do
            allow_any_instance_of(::Project).to receive(:suggested_reviewers_available?).and_return(true)
          end

          context 'when suggested reviews is not enabled for the project' do
            before do
              allow_any_instance_of(::Project).to receive(:suggested_reviewers_enabled).and_return(false)
            end

            it 'returns without calling the fetch suggested reviewer service', :aggregate_failures do
              expect(::Projects::RegisterSuggestedReviewersProjectService).not_to receive(:new)

              subject.perform(project.id, user.id)
            end
          end

          context 'when suggested reviews is enabled for the project' do
            before do
              allow_any_instance_of(::Project).to receive(:suggested_reviewers_enabled).and_return(true)
            end

            context 'when service returns success' do
              let(:registration_result) do
                {
                  project_id: project.id,
                  registered_at: '2022-01-01 09:00'
                }
              end

              let(:response) do
                ServiceResponse.success(payload: registration_result)
              end

              it 'calls project register service and logs an info with payload', :aggregate_failures do
                allow_next_instance_of(::Projects::RegisterSuggestedReviewersProjectService) do |instance|
                  allow(instance).to receive(:execute).and_return(response)
                end

                expect(subject).to receive(:log_extra_metadata_on_done)
                  .with(:project_id, response.payload[:project_id])
                expect(subject).to receive(:log_extra_metadata_on_done)
                  .with(:registered_at, response.payload[:registered_at])

                subject.perform(project.id, user.id)
              end
            end

            context 'when service returns error' do
              context 'when error is trackable' do
                let(:response) do
                  ServiceResponse.error(message: 'Failed to create access token', reason: :token_creation_failed)
                end

                it 'tracks the error' do
                  allow_next_instance_of(::Projects::RegisterSuggestedReviewersProjectService) do |instance|
                    allow(instance).to receive(:execute).and_return(response)
                  end

                  expect(Gitlab::ErrorTracking)
                    .to receive(:track_exception)
                          .with(an_instance_of(StandardError), { project_id: project.id })
                          .and_call_original

                  subject.perform(project.id, user.id)
                end
              end

              context 'when error is swallowable' do
                let(:response) do
                  ServiceResponse.error(message: 'Project is already registered', reason: :project_already_registered)
                end

                it 'swallows the error' do
                  allow_next_instance_of(::Projects::RegisterSuggestedReviewersProjectService) do |instance|
                    allow(instance).to receive(:execute).and_return(response)
                  end

                  expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

                  subject.perform(project.id, user.id)
                end
              end

              context 'when error is trackable and raisable' do
                let(:response) do
                  ServiceResponse.error(message: 'Failed to register project', reason: :client_request_failed)
                end

                it 'tracks and raises the error', :aggregate_failures do
                  allow_next_instance_of(::Projects::RegisterSuggestedReviewersProjectService) do |instance|
                    allow(instance).to receive(:execute).and_return(response)
                  end

                  expect(Gitlab::ErrorTracking)
                    .to receive(:track_and_raise_exception)
                          .with(an_instance_of(StandardError), { project_id: project.id })
                          .and_call_original

                  expect { subject.perform(project.id, user.id) }
                    .to raise_error(StandardError, 'Failed to register project')
                end
              end
            end
          end
        end
      end
    end
  end
  # rubocop:enable RSpec/AnyInstanceOf
end
