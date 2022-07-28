# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RequirementsManagement::UpdateRequirementService do
  let_it_be(:title) { 'title' }
  let_it_be(:description) { 'description' }

  let(:new_title) { 'new title' }
  let(:new_description) { 'new description' }

  let_it_be(:project) { create(:project)}
  let_it_be(:user) { create(:user) }

  let!(:requirement) { create(:requirement, project: project, title: title, description: description, state: :opened) }

  let(:params) do
    {
      title: new_title,
      description: new_description,
      state: 'archived',
      created_at: 2.days.ago,
      author_id: create(:user).id
    }
  end

  subject { described_class.new(project, user, params).execute(requirement) }

  describe '#execute' do
    before do
      stub_licensed_features(requirements: true)
    end

    context 'when user can update requirements' do
      before do
        project.add_reporter(user)
      end

      it 'updates the requirement with only permitted params', :aggregate_failures do
        is_expected.to have_attributes(
          errors: be_empty,
          title: params[:title],
          state: params[:state]
        )
        is_expected.not_to have_attributes(
          created_at: params[:created_at],
          author_id: params[:author_id]
        )
      end

      context 'when updating title, description or state' do
        shared_examples 'keeps requirement and its requirement_issue in sync' do
          it 'keeps title and description in sync' do
            subject

            requirement.reload
            requirement.requirement_issue.reload

            expect(requirement).to have_attributes(
              title: requirement.requirement_issue.title,
              description: requirement.requirement_issue.description)

            # Both objects (Requirement | Requirement Issue) state enums have the same integers
            # but on Requirement 'closed' means 'archived'.
            # requirement: enum state: { opened: 1, archived: 2 }
            # issue:       STATE_ID_MAP = { opened: 1, closed: 2, ...
            expect(requirement.read_attribute_before_type_cast(:state)).to eq(requirement.requirement_issue.state_id)
          end
        end

        shared_examples 'does not persist any changes' do
          it 'does not update the requirement' do
            expect { subject }.not_to change { requirement.reload.attributes }
          end

          it 'does not update the requirement issue' do
            expect { subject }.not_to change { requirement_issue.reload.attributes }
          end
        end

        context 'if there is an associated requirement_issue' do
          let!(:requirement_issue) { create(:requirement_issue, requirement: requirement, title: title, description: description, state: :opened) }

          let(:params) do
            { title: new_title, description: new_description }
          end

          it 'updates the synced requirement_issue with title and description' do
            expect { subject }
              .to change { requirement.requirement_issue.description }.from(description).to(new_description)
              .and change { requirement.requirement_issue.title }.from(title).to(new_title)
          end

          context 'when updating title' do
            let(:params) do
              { title: new_title }
            end

            it "updates requirement's issue title" do
              expect { subject }.to change { requirement.requirement_issue.reload.title }.from(title).to(new_title)
            end

            it_behaves_like 'keeps requirement and its requirement_issue in sync'
          end

          context 'when updating description' do
            let(:params) do
              { description: new_description }
            end

            it "updates requirement's issue description" do
              expect { subject }.to change { requirement.requirement_issue.reload.description }.from(description).to(new_description)
            end

            it_behaves_like 'keeps requirement and its requirement_issue in sync'
          end

          context 'when updating state' do
            context 'to archived' do
              let(:params) { { state: 'archived' } }

              it 'closes issue' do
                expect_next_instance_of(::Issues::CloseService) do |service|
                  expect(service).to receive(:execute).with(requirement_issue, any_args).and_call_original
                end

                expect { subject }.to change { requirement.requirement_issue.reload.state }.from('opened').to('closed')
              end
            end

            context 'to opened' do
              let(:params) { { state: 'opened' } }

              before do
                requirement_issue.close
                requirement.update!(state: 'archived')
              end

              it 'reopens issue' do
                expect_next_instance_of(::Issues::ReopenService) do |service|
                  expect(service).to receive(:execute).with(requirement_issue, any_args).and_call_original
                end

                expect { subject }.to change { requirement.requirement_issue.reload.state }.from('closed').to('opened')
              end
            end
          end

          context 'if update fails' do
            let(:params) do
              { title: nil }
            end

            it_behaves_like 'does not persist any changes'
            it_behaves_like 'keeps requirement and its requirement_issue in sync'

            context 'if update of requirement succeeds but update of issue fails' do
              let(:params) do
                { title: 'some magically valid title for requirement but not issue' }
              end

              before do
                allow_next_instance_of(::Issues::UpdateService) do |service|
                  allow(service).to receive(:execute).and_return(requirement_issue)
                end

                allow_next_instance_of(::Issues::ReopenService) do |service|
                  allow(service).to receive(:execute).and_return(requirement_issue)
                end

                allow_next_instance_of(::Issues::CloseService) do |service|
                  allow(service).to receive(:execute).and_return(requirement_issue)
                end

                allow(requirement).to receive(:requirement_issue).and_return(requirement_issue)
                allow(requirement_issue).to receive(:valid?).and_return(false).at_least(:once)
              end

              it_behaves_like 'keeps requirement and its requirement_issue in sync'
              it_behaves_like 'does not persist any changes'

              it 'adds an informative sync error to issue' do
                expect(::Gitlab::AppLogger).to receive(:info).with(a_hash_including(message: /Associated issue/))

                subject

                expect(requirement.errors[:base]).to include(/Associated issue/)
              end
            end
          end
        end

        it 'does not call the Issues::UpdateService when requirement is invalid' do
          requirement.project = nil
          expect(Issues::UpdateService).not_to receive(:new)

          subject
        end
      end

      context 'when updating last test report state' do
        context 'as passing' do
          it 'creates passing test report with null build_id' do
            service = described_class.new(project, user, { last_test_report_state: 'passed' })

            expect { service.execute(requirement) }.to change { RequirementsManagement::TestReport.count }.from(0).to(1)
            test_report = requirement.test_reports.last
            expect(requirement.last_test_report_state).to eq('passed')
            expect(requirement.last_test_report_manually_created?).to eq(true)
            expect(test_report.state).to eq('passed')
            expect(test_report.build).to eq(nil)
            expect(test_report.author).to eq(user)
          end
        end

        context 'as failed' do
          it 'creates failing test report with null build_id' do
            service = described_class.new(project, user, { last_test_report_state: 'failed' })

            expect { service.execute(requirement) }.to change { RequirementsManagement::TestReport.count }.from(0).to(1)
            test_report = requirement.test_reports.last
            expect(requirement.last_test_report_state).to eq('failed')
            expect(requirement.last_test_report_manually_created?).to eq(true)
            expect(test_report.state).to eq('failed')
            expect(test_report.build).to eq(nil)
            expect(test_report.author).to eq(user)
          end
        end

        context 'when user cannot create test reports' do
          it 'does not create test report' do
            allow(Ability).to receive(:allowed?).and_call_original
            allow(Ability).to receive(:allowed?).with(user, :create_requirement_test_report, project).and_return(false)
            service = described_class.new(project, user, { last_test_report_state: 'failed' })

            expect { service.execute(requirement) }.not_to change { RequirementsManagement::TestReport.count }
          end
        end
      end
    end

    context 'when user is not allowed to update requirements' do
      it 'raises an exception' do
        expect { subject }.to raise_exception(Gitlab::Access::AccessDeniedError)
      end
    end
  end
end
