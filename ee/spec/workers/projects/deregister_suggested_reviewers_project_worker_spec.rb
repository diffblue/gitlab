# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::DeregisterSuggestedReviewersProjectWorker, feature_category: :code_review_workflow do
  let(:project) { build_stubbed(:project) }
  let(:user) { build_stubbed(:user) }
  let(:service) { instance_spy(::Projects::DeregisterSuggestedReviewersProjectService) }

  subject { described_class.new }

  describe '#perform' do
    before do
      allow(::Project).to receive(:find_by_id).and_return(project)
      allow(::User).to receive(:find_by_id).and_return(user)

      allow(::Projects::DeregisterSuggestedReviewersProjectService).to receive(:new).and_return(service)
    end

    context 'when project is not found' do
      it 'returns without calling the deregister service' do
        subject.perform(non_existing_record_id, user.id)

        expect(service).not_to have_received(:execute)
      end
    end

    context 'when project is found' do
      context 'when user is not found' do
        it 'returns without calling the deregister service' do
          subject.perform(project.id, non_existing_record_id)

          expect(service).not_to have_received(:execute)
        end
      end

      context 'when user is found' do
        context 'when suggested reviews is not available for the project' do
          before do
            allow(project).to receive(:suggested_reviewers_available?).and_return(false)
          end

          it 'returns without calling the deregister service', :aggregate_failures do
            subject.perform(project.id, user.id)

            expect(service).not_to have_received(:execute)
          end
        end

        context 'when suggested reviews is available for the project' do
          before do
            allow(project).to receive(:suggested_reviewers_available?).and_return(true)
          end

          context 'when suggested reviews is enabled for the project' do
            before do
              allow(project).to receive(:suggested_reviewers_enabled).and_return(true)
            end

            it 'returns without calling the deregister service', :aggregate_failures do
              subject.perform(project.id, user.id)

              expect(service).not_to have_received(:execute)
            end
          end

          context 'when suggested reviews is not enabled for the project' do
            before do
              allow(project).to receive(:suggested_reviewers_enabled).and_return(false)
            end

            context 'when service returns success' do
              let(:deregistration_result) do
                {
                  project_id: project.id,
                  deregistered_at: '2022-01-01 09:00'
                }
              end

              let(:response) do
                ServiceResponse.success(payload: deregistration_result)
              end

              it 'calls deregister service and logs an info with payload', :aggregate_failures do
                allow(service).to receive(:execute).and_return(response)

                expect(subject)
                  .to receive(:log_hash_metadata_on_done)
                        .with(
                          project_id: response.payload[:project_id],
                          deregistered_at: response.payload[:deregistered_at]
                        )

                subject.perform(project.id, user.id)
              end
            end

            context 'when service returns error' do
              context 'when error is swallowable' do
                let(:response) do
                  ServiceResponse.error(
                    message: 'Project is not found',
                    reason: :project_not_found
                  )
                end

                it 'swallows the error' do
                  allow(service).to receive(:execute).and_return(response)

                  expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

                  subject.perform(project.id, user.id)
                end
              end

              context 'when error is trackable and raisable' do
                let(:response) do
                  ServiceResponse.error(message: 'Failed to deregister project', reason: :client_request_failed)
                end

                it 'tracks and raises the error', :aggregate_failures do
                  allow(service).to receive(:execute).and_return(response)

                  expect(Gitlab::ErrorTracking)
                    .to receive(:track_and_raise_exception)
                          .with(an_instance_of(StandardError), { project_id: project.id })
                          .and_call_original

                  expect { subject.perform(project.id, user.id) }
                    .to raise_error(StandardError, 'Failed to deregister project')
                end
              end
            end
          end
        end
      end
    end
  end
end
