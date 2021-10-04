# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::CreateService do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, group: group) }

  let(:params) { { title: 'Awesome issue', description: 'please fix', weight: 9 } }
  let(:service) { described_class.new(project: project, current_user: user, params: params, spam_params: nil) }

  describe '#execute' do
    context 'when current user cannot admin issues in the project' do
      before do
        project.add_guest(user)
      end

      it 'filters out params that cannot be set without the :admin_issue permission' do
        issue = service.execute

        expect(issue).to be_persisted
        expect(issue.weight).to be_nil
      end
    end

    context 'when current user can admin issues in the project' do
      before do
        stub_licensed_features(epics: true)
        project.add_reporter(user)
      end

      it 'sets permitted params correctly' do
        issue = service.execute

        expect(issue).to be_persisted
        expect(issue.weight).to eq(9)
      end

      context 'when epics are enabled' do
        let_it_be(:epic) { create(:epic, group: group, start_date_is_fixed: false, due_date_is_fixed: false) }

        before do
          stub_licensed_features(epics: true)
          project.add_reporter(user)
        end

        it_behaves_like 'issue with epic_id parameter' do
          let(:execute) { service.execute }
        end

        context 'when using quick actions' do
          before do
            group.add_reporter(user)
          end

          context '/epic action' do
            let(:params) { { title: 'New issue', description: "/epic #{epic.to_reference(project)}" } }

            it 'adds an issue to the passed epic' do
              issue = service.execute

              expect(issue).to be_persisted
              expect(issue.reload.epic).to eq(epic)
              expect(issue.confidential).to eq(false)
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
              issue = service.execute

              expect(issue.milestone).to eq(milestone)
              expect(issue.reload.epic).to eq(epic)
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
            it 'creates confidential child issue' do
              confidential_epic = create(:epic, group: group, confidential: true)
              params = { title: 'confidential issue', epic_id: confidential_epic.id }

              issue = described_class.new(project: project, current_user: user, params: params, spam_params: nil).execute

              expect(issue.confidential).to eq(true)
            end
          end

          context 'when adding a confidential issue to public epic' do
            it 'creates a confidential child issue' do
              params = { title: 'confidential issue', epic_id: epic.id, confidential: true }

              issue = described_class.new(project: project, current_user: user, params: params, spam_params: nil).execute

              expect(issue.confidential).to eq(true)
            end
          end
        end
      end
    end

    it_behaves_like 'new issuable with scoped labels' do
      let(:parent) { project }
    end
  end
end
