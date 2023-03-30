# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::MoveService, feature_category: :team_planning do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:old_project) { create(:project, group: group) }
  let(:new_project) { create(:project, group: group) }
  let(:old_issue) { create(:issue, project: old_project, author: user) }
  let(:move_service) { described_class.new(container: old_project, current_user: user) }

  before do
    old_project.add_reporter(user)
    new_project.add_reporter(user)
  end

  describe '#execute' do
    context 'group issue hooks' do
      let!(:hook) { create(:group_hook, group: new_project.group, issues_events: true) }

      it 'executes group issue hooks' do
        allow_next_instance_of(WebHookService) do |instance|
          allow(instance).to receive(:execute)
        end

        # Ideally, we'd test that `WebHookWorker.jobs.size` increased by 1,
        # but since the entire spec run takes place in a transaction, we never
        # actually get to the `after_commit` hook that queues these jobs.
        expect { move_service.execute(old_issue, new_project) }
          .not_to raise_error # Sidekiq::Worker::EnqueueFromTransactionError
      end

      context 'when moved issue belongs to epic' do
        it 'records epic moved from project event' do
          create(:epic_issue, issue: old_issue)
          expect(Gitlab::UsageDataCounters::EpicActivityUniqueCounter).to receive(:track_epic_issue_moved_from_project)
            .with(author: user, namespace: group)

          move_service.execute(old_issue, new_project)
        end
      end

      context 'when moved issue does not belong to epic' do
        it 'does not record epic moved from project event' do
          expect(Gitlab::UsageDataCounters::EpicActivityUniqueCounter).not_to receive(:track_epic_issue_moved_from_project)
            .with(author: user, namespace: group)

          move_service.execute(old_issue, new_project)
        end
      end

      context 'when it is not allowed to move issues of given type' do
        it 'throws error' do
          requirement_issue = create(:issue, :requirement, project: old_project)

          expect { move_service.execute(requirement_issue, new_project) }
            .to raise_error(StandardError, 'Cannot move issues of \'requirement\' type.')
        end
      end
    end

    context 'resource weight events' do
      let(:old_issue) { create(:issue, project: old_project, author: user, weight: 5) }
      let!(:event1) { create(:resource_weight_event, issue: old_issue, weight: 1) }
      let!(:event2) { create(:resource_weight_event, issue: old_issue, weight: 42) }
      let!(:event3) { create(:resource_weight_event, issue: old_issue, weight: 5) }

      let!(:another_old_issue) { create(:issue, project: new_project, author: user) }
      let!(:event4) { create(:resource_weight_event, issue: another_old_issue, weight: 2) }

      it 'creates expected resource weight events' do
        new_issue = move_service.execute(old_issue, new_project)

        expect(new_issue.resource_weight_events.map(&:weight)).to contain_exactly(1, 42, 5)
      end
    end
  end

  describe '#rewrite_related_vulnerability_issues' do
    let(:user) { create(:user) }

    let!(:vulnerabilities_issue_link) { create(:vulnerabilities_issue_link, issue: old_issue) }

    it 'updates all vulnerability issue links with new issue' do
      new_issue = move_service.execute(old_issue, new_project)

      expect(vulnerabilities_issue_link.reload.issue).to eq(new_issue)
    end
  end

  describe '#rewrite_epic_issue' do
    context 'issue assigned to epic' do
      let(:epic) { create(:epic, group: group) }
      let!(:epic_issue) { create(:epic_issue, issue: old_issue, epic: epic) }

      before do
        stub_licensed_features(epics: true)
      end

      it 'updates epic issue reference' do
        epic_issue.epic.group.add_reporter(user)

        new_issue = move_service.execute(old_issue, new_project)

        expect(new_issue.epic_issue).to eq(epic_issue)
      end

      describe 'events tracking', :snowplow do
        subject(:issue_move) { move_service.execute(old_issue, new_project) }

        before do
          epic_issue.epic.group.add_reporter(user)
        end

        it 'tracks usage data for changed epic action' do
          expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_changed_epic_action)
                                                                             .with(author: user, project: new_project)

          subject
        end

        it_behaves_like 'issue_edit snowplow tracking' do
          let(:property) { Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_CHANGED_EPIC }
          let(:project) { new_project }
        end
      end

      context 'user can not update the epic' do
        it 'ignores epic issue reference' do
          new_issue = move_service.execute(old_issue, new_project)

          expect(new_issue.epic_issue).to be_nil
        end

        it 'does not send usage data for changed epic action' do
          expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).not_to receive(:track_issue_changed_epic_action)

          move_service.execute(old_issue, new_project)
        end
      end

      context 'epic update fails' do
        it 'does not send usage data for changed epic action' do
          allow_next_instance_of(::EpicIssue) do |epic_issue|
            allow(epic_issue).to receive(:update).and_return(false)
          end

          expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).not_to receive(:track_issue_changed_epic_action)

          move_service.execute(old_issue, new_project)
        end
      end
    end
  end

  describe '#delete_pending_escalations' do
    let!(:pending_escalation) { create(:incident_management_pending_issue_escalation, issue: old_issue) }

    it 'deletes the pending escalations for the incident' do
      new_issue = move_service.execute(old_issue, new_project)

      expect(new_issue.pending_escalations.count).to eq(0)
      expect(old_issue.pending_escalations.count).to eq(0)
      expect { pending_escalation.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
