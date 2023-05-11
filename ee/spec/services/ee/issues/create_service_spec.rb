# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::CreateService, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, group: group) }

  let(:base_params) { { title: 'Awesome issue', description: 'please fix', weight: 9 } }
  let(:additional_params) { {} }
  let(:params) { base_params.merge(additional_params) }
  let(:service) { described_class.new(container: project, current_user: user, params: params, spam_params: nil) }
  let(:created_issue) { service.execute[:issue] }

  describe '#execute' do
    context 'when current user cannot admin issues in the project' do
      let_it_be(:iteration) { create(:iteration, iterations_cadence: create(:iterations_cadence, group: group), start_date: 14.days.ago, due_date: 5.days.ago) }

      let(:additional_params) { { iteration: iteration, sprint_id: iteration.id } }

      before do
        project.add_guest(user)
        stub_licensed_features(iterations: true)
      end

      it 'filters out params that cannot be set without the :admin_issue permission' do
        expect(created_issue).to be_persisted
        expect(created_issue.weight).to be_nil
        expect(created_issue.iteration).to be_nil
      end
    end

    context 'when current user can admin issues in the project' do
      before do
        stub_licensed_features(epics: true)
        project.add_reporter(user)
      end

      it 'sets permitted params correctly' do
        expect(created_issue).to be_persisted
        expect(created_issue.weight).to eq(9)
      end

      context 'when epics are enabled' do
        let_it_be(:epic) { create(:epic, group: group, start_date_is_fixed: false, due_date_is_fixed: false) }

        before do
          stub_licensed_features(epics: true)
          project.add_reporter(user)
        end

        it_behaves_like 'issue with epic_id parameter' do
          let(:execute) { service.execute }
          let(:returned_issue) { execute[:issue] }
        end

        context 'when using quick actions' do
          before do
            group.add_reporter(user)
          end

          context '/epic action' do
            let(:params) { { title: 'New issue', description: "/epic #{epic.to_reference(project)}" } }

            it 'adds an issue to the passed epic' do
              expect(created_issue).to be_persisted
              expect(created_issue.reload.epic).to eq(epic)
              expect(created_issue.confidential).to eq(false)
            end
          end

          context 'with epic and milestone in commands only' do
            let_it_be(:milestone) { create(:milestone, group: group, start_date: Date.today, due_date: 7.days.from_now) }
            let_it_be(:assignee_user1) { create(:user) }

            before do
              project.add_guest(assignee_user1)
            end

            let(:params) do
              {
                title: 'Awesome issue',
                description: %(/epic #{epic.to_reference}\n/milestone #{milestone.to_reference}\n/assign #{assignee_user1.to_reference})
              }
            end

            it 'sets epic and milestone to issuable and update epic start and due date' do
              expect(created_issue.milestone).to eq(milestone)
              expect(created_issue.reload.epic).to eq(epic)
              expect(epic.reload.start_date).to eq(milestone.start_date)
              expect(epic.due_date).to eq(milestone.due_date)
            end

            it 'generates system notes for adding an epic and milestone', :sidekiq_inline do
              expect { service.execute }.to change(Note, :count).by(3).and(change(ResourceMilestoneEvent, :count).by(1))
            end

            context 'when assigning epic raises an exception' do
              let(:mock_service) { double('service', execute: { status: :error, message: 'failed to assign epic' }) }

              it 'assigns the issue passed to the provided epic' do
                expect(EpicIssues::CreateService).to receive(:new).and_return(mock_service)

                expect { service.execute }.to raise_error(EE::Issues::BaseService::EpicAssignmentError, 'failed to assign epic')
              end
            end
          end

          context 'when adding a public issue to confidential epic' do
            let(:confidential_epic) { create(:epic, group: group, confidential: true) }
            let(:params) { { title: 'confidential issue', epic_id: confidential_epic.id } }

            it 'creates confidential child issue' do
              expect(created_issue).to be_confidential
            end
          end

          context 'when adding a confidential issue to public epic' do
            let(:params) { { title: 'confidential issue', epic_id: epic.id, confidential: true } }

            it 'creates a confidential child issue' do
              expect(created_issue).to be_confidential
            end
          end
        end
      end

      context 'when iterations are available' do
        let_it_be(:iteration_cadence1) { create(:iterations_cadence, group: group) }
        let_it_be(:iteration_cadence2) { create(:iterations_cadence, group: group) }
        let_it_be(:current_iteration1) { create(:iteration, iterations_cadence: iteration_cadence1, start_date: 4.days.ago, due_date: 3.days.from_now) }
        let_it_be(:current_iteration2) { create(:iteration, iterations_cadence: iteration_cadence2, start_date: 4.days.ago, due_date: 3.days.from_now) }
        let_it_be(:future_iteration) { create(:iteration, iterations_cadence: iteration_cadence1, start_date: 6.days.from_now, due_date: 13.days.from_now) }

        before do
          stub_licensed_features(iterations: true)
        end

        RSpec.shared_examples 'create with specify column' do |column|
          context 'when user can read the given iteration' do
            let(:additional_params) { { column => future_iteration.id } }

            it 'is successful, and assigns the specified iteration to the issue' do
              expect(created_issue).to be_persisted
              expect(created_issue).to have_attributes(iteration: future_iteration)
            end
          end

          context "when user can't read the given iteration" do
            let(:private_group) { create(:group, :private) }
            let(:additional_params) { { column => create(:iteration, iterations_cadence: create(:iterations_cadence, group: private_group)).id } }

            it 'is successful but does not assign the iteration' do
              expect(created_issue).to be_persisted
              expect(created_issue).to have_attributes(iteration: nil)
            end
          end

          context 'when iteration_wildcard_id is provided' do
            let(:additional_params) { { column => future_iteration.id, iteration_wildcard_id: 'CURRENT', iteration_cadence_id: iteration_cadence2.id } }

            it 'raises a mutually exclusive argument error' do
              expect { service.execute }.to raise_error(
                ::Issues::BaseService::IterationAssignmentError,
                "Incompatible arguments: #{column}, iteration_wildcard_id."
              )
            end
          end
        end

        context 'when sprint_id is provided' do
          it_behaves_like 'create with specify column', :sprint_id
        end

        context 'when iteration_id is provided' do
          it_behaves_like 'create with specify column', :iteration_id
        end

        context 'when both sprint_id and iteration_id is provided' do
          let(:additional_params) { { sprint_id: future_iteration.id, iteration_id: future_iteration.id } }

          it 'raises a mutually exclusive argument error' do
            expect { service.execute }.to raise_error(
              ::Issues::BaseService::IterationAssignmentError,
              'Incompatible arguments: iteration_id, sprint_id.'
            )
          end
        end

        context 'when iteration_wildcard_id is provided' do
          context 'when iteration_wildcard_id is CURRENT' do
            let(:additional_params) { { iteration_wildcard_id: 'CURRENT' } }

            context 'when iteration_cadence_id is provided' do
              let(:additional_params) { { iteration_wildcard_id: 'CURRENT', iteration_cadence_id: iteration_cadence2.id } }

              it 'is successful, and assigns the current iteration to the issue' do
                expect(created_issue).to be_persisted
                expect(created_issue).to have_attributes(iteration: current_iteration2)
              end
            end

            context 'when iteration_cadence_id is not provided' do
              it 'always requires iteration cadence id when wildcard is provided' do
                expect { service.execute }.to raise_error(
                  ::Issues::BaseService::IterationAssignmentError,
                  'iteration_cadence_id is required when iteration_wildcard_id is provided.'
                )
              end
            end
          end

          context 'when iteration_wildcard_id is invalid' do
            let(:additional_params) { { iteration_wildcard_id: 'INVALID', iteration_cadence_id: iteration_cadence2.id } }

            it 'is successful, and does not assign an iteration to the issue' do
              expect(created_issue).to be_persisted
              expect(created_issue).to have_attributes(iteration: nil)
            end
          end
        end

        context 'when no iteration params are provided' do
          it 'is successful, and does not assign an iteration to the issue' do
            expect(created_issue).to be_persisted
            expect(created_issue).to have_attributes(iteration: nil)
          end
        end
      end

      context 'when issue is of requirement_type' do
        let(:params) { { title: 'Requirement Issue', description: 'Should sync', issue_type: 'requirement' } }

        before_all do
          project.add_reporter(user)
        end

        before do
          stub_licensed_features(requirements: true)
        end

        it 'creates one requirement and one requirement issue' do
          expect { service.execute }.to change { Issue.count }.by(1)
            .and change { RequirementsManagement::Requirement.count }.by(1)
        end

        it 'creates a requirement object with same parameters' do
          result = service.execute
          issue = result[:issue]
          requirement = issue.reload.requirement

          expect(result).to be_success
          expect(requirement.title).to eq(issue.title)
          expect(requirement.description).to eq(issue.description)
          expect(requirement.state).to eq(issue.state)
          expect(requirement.project).to eq(issue.project)
          expect(requirement.author).to eq(issue.author)
          expect(issue.work_item_type.requirement?).to eq(true)
        end

        context 'when creation of requirement fails' do
          it 'does not create issue' do
            allow_next_instance_of(RequirementsManagement::Requirement) do |instance|
              allow(instance).to receive(:valid?).and_return(false)
            end

            expect { service.execute }.to change { Issue.count }.by(0)
              .and change { RequirementsManagement::Requirement.count }.by(0)
          end
        end

        context 'when creation of issue fails' do
          it 'does not create requirement' do
            allow_next_instance_of(Issue) do |instance|
              allow(instance).to receive(:valid?).and_return(false)
            end

            expect { service.execute }.to change { Issue.count }.by(0)
              .and change { RequirementsManagement::Requirement.count }.by(0)
          end
        end

        context 'when requirements feature is not available' do
          before do
            stub_licensed_features(requirements: false)
          end

          it 'creates a issue work item' do
            expect { service.execute }.to change { Issue.where(issue_type: 'issue').count }.by(1)
              .and change { RequirementsManagement::Requirement.count }.by(0)
          end
        end
      end
    end

    it_behaves_like 'new issuable with scoped labels' do
      let(:parent) { project }
      let(:service_result) { described_class.new(**args).execute }
      let(:issuable) { service_result[:issue] }
    end
  end
end
