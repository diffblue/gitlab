# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::RegisterSuggestedReviewersProjectWorker do
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
            let(:logger) { subject.send(:logger) }
            let(:example_registration_result) do
              {
                project_id: project.id,
                registered_at: '2022-01-01 09:00'
              }
            end

            let(:example_success_result) do
              example_registration_result.merge({ status: :success })
            end

            let(:example_error_result) do
              example_registration_result.merge({ status: :error })
            end

            before do
              allow_any_instance_of(::Project).to receive(:suggested_reviewers_enabled).and_return(true)
            end

            context 'when service returns success' do
              it 'calls project register service and logs an info with payload', :aggregate_failures do
                allow_next_instance_of(::Projects::RegisterSuggestedReviewersProjectService) do |instance|
                  allow(instance).to receive(:execute).and_return(example_success_result)
                end

                expect(subject).to receive(:log_extra_metadata_on_done).with(:project_id,
example_error_result[:project_id])
                expect(subject).to receive(:log_extra_metadata_on_done).with(:registered_at,
example_error_result[:registered_at])

                subject.perform(project.id, user.id)
              end
            end
          end
        end
      end
    end
  end
  # rubocop:enable RSpec/AnyInstanceOf
end
