# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::UpdateService do
  let_it_be(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, group: group) }
  let_it_be_with_reload(:issue) { create(:issue, project: project) }
  let_it_be(:epic) { create(:epic, group: group) }

  let(:author) { issue.author }
  let(:user) { author }

  describe 'execute' do
    before do
      project.add_reporter(author)
    end

    def update_issue(opts)
      described_class.new(project: project, current_user: user, params: opts).execute(issue)
    end

    context 'refresh epic dates' do
      before do
        issue.update!(epic: epic)
      end

      context 'updating milestone' do
        let_it_be(:milestone) { create(:milestone, project: project) }

        it 'calls UpdateDatesService' do
          expect(Epics::UpdateDatesService).to receive(:new).with([epic]).and_call_original.twice

          update_issue(milestone: milestone)
          update_issue(milestone_id: nil)
        end
      end

      context 'updating iteration' do
        let_it_be(:iteration) { create(:iteration, group: group) }

        context 'when issue does not already have an iteration' do
          it 'calls NotificationService#changed_iteration_issue' do
            expect_next_instance_of(NotificationService::Async) do |ns|
              expect(ns).to receive(:changed_iteration_issue)
            end

            update_issue(iteration: iteration)
          end
        end

        context 'when issue already has an iteration' do
          let_it_be(:old_iteration) { create(:iteration, group: group) }

          before do
            update_issue(iteration: old_iteration)
          end

          context 'setting to nil' do
            it 'calls NotificationService#removed_iteration_issue' do
              expect_next_instance_of(NotificationService::Async) do |ns|
                expect(ns).to receive(:removed_iteration_issue)
              end

              update_issue(iteration: nil)
            end
          end

          context 'setting to IssuableFinder::Params::NONE' do
            it 'calls NotificationService#removed_iteration_issue' do
              expect_next_instance_of(NotificationService::Async) do |ns|
                expect(ns).to receive(:removed_iteration_issue)
              end

              update_issue(sprint_id: IssuableFinder::Params::NONE)
            end

            it 'removes the iteration properly' do
              update_issue(sprint_id: IssuableFinder::Params::NONE)

              expect(issue.reload.iteration).to be_nil
            end
          end

          context 'setting to another iteration' do
            it 'calls NotificationService#changed_iteration_issue' do
              expect_next_instance_of(NotificationService::Async) do |ns|
                expect(ns).to receive(:changed_iteration_issue)
              end

              update_issue(iteration: iteration)
            end
          end
        end
      end

      context 'updating weight' do
        before do
          project.add_maintainer(user)
          issue.update!(weight: 3)
        end

        context 'when weight is integer' do
          it 'updates to the exact value' do
            expect { update_issue(weight: 2) }.to change { issue.weight }.to(2)
          end
        end

        context 'when weight is float' do
          it 'rounds the value down' do
            expect { update_issue(weight: 1.8) }.to change { issue.weight }.to(1)
          end
        end

        context 'when weight is zero' do
          it 'sets the value to zero' do
            expect { update_issue(weight: 0) }.to change { issue.weight }.to(0)
          end
        end

        context 'when weight is a string' do
          it 'sets the value to 0' do
            expect { update_issue(weight: 'abc') }.to change { issue.weight }.to(0)
          end
        end
      end

      it_behaves_like 'updating issuable health status' do
        let(:issuable) { issue }
        let(:parent) { project }
      end

      context 'updating other fields' do
        it 'does not call UpdateDatesService' do
          expect(Epics::UpdateDatesService).not_to receive(:new)
          update_issue(title: 'foo')
        end
      end
    end

    context 'assigning iteration' do
      before do
        stub_licensed_features(iterations: true)
        group.add_maintainer(user)
      end

      RSpec.shared_examples 'creates iteration resource event' do
        it 'creates a system note' do
          expect do
            update_issue(iteration: iteration)
          end.not_to change { Note.system.count }
        end

        it 'does not create a iteration change event' do
          expect do
            update_issue(iteration: iteration)
          end.to change { ResourceIterationEvent.count }.by(1)
        end
      end

      context 'group iterations' do
        let_it_be(:iteration) { create(:iteration, group: group) }

        it_behaves_like 'creates iteration resource event'
      end

      context 'project iterations' do
        let_it_be(:iteration) { create(:iteration, :skip_project_validation, project: project) }

        it_behaves_like 'creates iteration resource event'
      end
    end

    context 'changing issue_type' do
      let_it_be(:sla_setting) { create(:project_incident_management_setting, :sla_enabled, project: project) }

      before do
        stub_licensed_features(incident_sla: true, quality_management: true)
      end

      context 'from issue to incident' do
        shared_examples 'creates an SLA' do
          it do
            expect { update_issue(issue_type: 'incident') }.to change(IssuableSla, :count).by(1)
            expect(issue.reload).to be_incident
            expect(issue.reload.issuable_sla).to be_present
          end
        end

        it_behaves_like 'creates an SLA'

        context 'system note fails to be created' do
          before do
            expect_next_instance_of(Note) do |note|
              expect(note).to receive(:valid?).and_return(false)
            end
          end

          it_behaves_like 'creates an SLA'
        end
      end

      context 'from incident to issue' do
        let!(:issue) { create(:incident, project: project) }
        let!(:sla) { create(:issuable_sla, issue: issue) }

        it 'does not remove the SLA or create a new one' do
          expect { update_issue(issue_type: 'issue') }.not_to change(IssuableSla, :count)
          expect(issue.reload.issue_type).to eq('issue')
          expect(issue.reload.issuable_sla).to be_present
        end

        it 'destroys any pending escalations' do
          pending = create(:incident_management_pending_issue_escalation, issue: issue)
          pending_2 = create(:incident_management_pending_issue_escalation, issue: issue)

          update_issue(issue_type: 'issue')

          expect { pending.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { pending_2.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'from issue to restricted issue types' do
        context 'with permissions' do
          it 'changes the type' do
            expect { update_issue(issue_type: 'test_case') }
              .to change { issue.reload.issue_type }
              .from('issue')
              .to('test_case')
          end

          it 'does not create or remove an SLA' do
            expect { update_issue(issue_type: 'test_case') }.not_to change(IssuableSla, :count)
            expect(issue.issuable_sla).to be_nil
          end
        end

        context 'without sufficient permissions' do
          let_it_be(:guest) { create(:user) }

          let(:user) { guest }

          before do
            project.add_guest(guest)
          end

          it 'excludes the issue type param' do
            expect { update_issue(issue_type: 'test_case') }.not_to change { issue.reload.issue_type }
          end
        end
      end
    end

    context 'assigning epic' do
      before do
        stub_licensed_features(epics: true)
      end

      let(:params) { { epic: epic } }

      subject { update_issue(params) }

      context 'when a user does not have permissions to assign an epic' do
        before do
          project.add_guest(author)
        end

        it 'raises an exception' do
          expect { subject }.to raise_error(Gitlab::Access::AccessDeniedError)
        end
      end

      context 'when a user has permissions to assign an epic' do
        before do
          group.add_guest(user)
        end

        context 'when EpicIssues::CreateService returns failure', :aggregate_failures do
          it 'does not send usage data for added or changed epic action' do
            link_sevice = double
            expect(EpicIssues::CreateService).to receive(:new)
                                                   .with(epic, user, { target_issuable: issue, skip_epic_dates_update: true })
                                                   .and_return(link_sevice)
            expect(link_sevice).to receive(:execute).and_return({ status: :failure })

            expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).not_to receive(:track_issue_added_to_epic_action)

            subject
          end
        end

        context 'when issue does not belong to an epic yet' do
          it 'assigns an issue to the provided epic' do
            expect { update_issue(epic: epic) }.to change { issue.reload.epic }.from(nil).to(epic)
          end

          it 'calls EpicIssues::CreateService' do
            link_sevice = double
            expect(EpicIssues::CreateService).to receive(:new)
              .with(epic, user, { target_issuable: issue, skip_epic_dates_update: true })
              .and_return(link_sevice)
            expect(link_sevice).to receive(:execute).and_return({ status: :success })

            subject
          end

          describe 'events tracking', :snowplow do
            it 'tracks usage data for added to epic action' do
              expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_added_to_epic_action)
                                                                                 .with(author: user, project: project)

              subject
            end

            it_behaves_like 'Snowplow event tracking' do
              let(:category) { 'issues_edit' }
              let(:action) { 'g_project_management_issue_added_to_epic' }
              let(:namespace) { project.namespace}
              let(:feature_flag_name) { :route_hll_to_snowplow_phase2 }
            end
          end
        end

        context 'when issue belongs to another epic' do
          let_it_be(:epic2) { create(:epic, group: group) }

          before do
            issue.update!(epic: epic2)
          end

          it 'assigns the issue passed to the provided epic' do
            expect { subject }.to change { issue.reload.epic }.from(epic2).to(epic)
          end

          it 'calls EpicIssues::CreateService' do
            link_sevice = double
            expect(EpicIssues::CreateService).to receive(:new)
              .with(epic, user, { target_issuable: issue, skip_epic_dates_update: true })
              .and_return(link_sevice)
            expect(link_sevice).to receive(:execute).and_return({ status: :success })

            subject
          end

          describe 'events tracking', :snowplow do
            it 'tracks usage data for changed epic action' do
              expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_changed_epic_action).with(author: user,
                                                                                                                              project: issue.project)

              subject
            end

            it_behaves_like 'Snowplow event tracking' do
              let(:category) { 'issues_edit' }
              let(:action) { 'g_project_management_issue_changed_epic' }
              let(:namespace) { issue.project.namespace}
              let(:project) { issue.project }
              let(:feature_flag_name) { :route_hll_to_snowplow_phase2 }
            end
          end
        end

        context 'when updating issue epic and milestone and assignee attributes' do
          let_it_be(:milestone) { create(:milestone, project: project) }
          let_it_be(:assignee_user1) { create(:user) }

          let(:params) { { epic: epic, milestone: milestone, assignees: [assignee_user1] } }

          before do
            project.add_guest(assignee_user1)
          end

          it 'assigns the issue passed to the provided epic', :sidekiq_inline do
            expect do
              subject
              issue.reload
            end.to change { issue.epic }.from(nil).to(epic)
                   .and(change { issue.milestone }.from(nil).to(milestone))
                   .and(change(ResourceMilestoneEvent, :count).by(1))
                   .and(change(Note, :count).by(3))
          end

          context 'when milestone and epic attributes are changed from description' do
            let(:params) { { description: %(/epic #{epic.to_reference}\n/milestone #{milestone.to_reference}\n/assign #{assignee_user1.to_reference}) } }

            it 'assigns the issue passed to the provided epic', :sidekiq_inline do
              expect do
                subject
                issue.reload
              end.to change { issue.epic }.from(nil).to(epic)
                     .and(change { issue.assignees }.from([]).to([assignee_user1]))
                     .and(change { issue.milestone }.from(nil).to(milestone))
                     .and(change(ResourceMilestoneEvent, :count).by(1))
                     .and(change(Note, :count).by(4))
            end
          end

          context 'when assigning epic raises an exception' do
            let(:mock_service) { double('service', execute: { status: :error, message: 'failed to assign epic' }) }

            it 'assigns the issue passed to the provided epic' do
              expect(EpicIssues::CreateService).to receive(:new).and_return(mock_service)

              expect { subject }.to raise_error(EE::Issues::BaseService::EpicAssignmentError, 'failed to assign epic')
            end
          end
        end
      end
    end

    context 'removing epic' do
      before do
        stub_licensed_features(epics: true)
      end

      subject { update_issue(epic: nil) }

      context 'when a user has permissions to assign an epic' do
        before do
          group.add_maintainer(user)
        end

        context 'when issue does not belong to an epic yet' do
          it 'does not do anything' do
            expect { subject }.not_to change { issue.reload.epic }
          end

          describe 'events tracking', :snowplow do
            it 'does not send usage data for removed epic action' do
              expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).not_to receive(:track_issue_removed_from_epic_action)

              subject
            end

            it 'does not send a Snowplow event' do
              subject

              expect_no_snowplow_event
            end
          end
        end

        context 'when issue belongs to an epic' do
          before do
            issue.update!(epic: epic)
          end

          it 'unassigns the epic' do
            expect { subject }.to change { issue.reload.epic }.from(epic).to(nil)
          end

          it 'calls EpicIssues::DestroyService' do
            link_sevice = double
            expect(EpicIssues::DestroyService).to receive(:new).with(EpicIssue.last, user).and_return(link_sevice)
            expect(link_sevice).to receive(:execute).and_return({ status: :success })

            subject
          end

          describe 'events tracking', :snowplow do
            it 'tracks usage data for removed from epic action' do
              expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_removed_from_epic_action)
                                                                                 .with(author: user, project: project)

              subject
            end

            it_behaves_like 'Snowplow event tracking' do
              let(:category) { 'issues_edit' }
              let(:action) { 'g_project_management_issue_removed_from_epic' }
              let(:namespace) { project.namespace}
              let(:feature_flag_name) { :route_hll_to_snowplow_phase2 }
            end
          end

          context 'but EpicIssues::DestroyService returns failure', :aggregate_failures do
            it 'does not send usage data for removed epic action' do
              link_sevice = double
              expect(EpicIssues::DestroyService).to receive(:new).with(EpicIssue.last, user).and_return(link_sevice)
              expect(link_sevice).to receive(:execute).and_return({ status: :failure })
              expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).not_to receive(:track_issue_removed_from_epic_action)

              subject
            end
          end
        end
      end
    end

    context 'updating escalation status' do
      let(:opts) { { escalation_status: { policy: policy } } }
      let(:escalation_update_class) { ::IncidentManagement::IssuableEscalationStatuses::AfterUpdateService }

      let!(:policy) { create(:incident_management_escalation_policy, project: project) }

      before do
        stub_licensed_features(oncall_schedules: true, escalation_policies: true)
        group.add_developer(user)
      end

      # Requires `expoected_policy` and `expected_status` to be defined
      shared_examples 'updates the escalation status record' do
        let(:service_double) { instance_double(escalation_update_class) }

        it 'has correct values' do
          update_issue(opts)

          expect(issue.escalation_status.policy).to eq(expected_policy)
          expect(issue.escalation_status.status_name).to eq(expected_status)
        end

        it 'triggers side-effects' do
          expect(escalation_update_class).to receive(:new).with(issue, user, status_change_reason: nil).and_return(service_double)
          expect(service_double).to receive(:execute)
          expect(project).to receive(:execute_hooks).with(an_instance_of(Hash), :issue_hooks)
          expect(project).to receive(:execute_integrations).with(an_instance_of(Hash), :issue_hooks)

          update_issue(opts)
        end
      end

      shared_examples 'does not change the status record' do
        specify do
          expect { update_issue(opts) }.not_to change { issue.reload.escalation_status }
        end

        it 'does not trigger side-effects' do
          expect(project).not_to receive(:execute_hooks)
          expect(project).not_to receive(:execute_integrations)

          update_issue(opts)
        end
      end

      context 'with an existing escalation status record' do
        let!(:escalation_status) { create(:incident_management_issuable_escalation_status, issue: issue) }

        context 'when issue is an incident' do
          let(:issue) { create(:incident, project: project) }

          context 'setting the escalation policy' do
            include_examples 'updates the escalation status record' do
              let(:expected_policy) { policy }
              let(:expected_status) { :triggered }
            end

            context 'with the policy value defined but unchanged' do
              let!(:escalation_status) { create(:incident_management_issuable_escalation_status, :paging, issue: issue, policy: policy) }

              it_behaves_like 'does not change the status record'
            end
          end

          context 'unsetting the escalation policy' do
            let(:policy) { nil }

            context 'when the policy is already set' do
              let!(:escalation_status) { create(:incident_management_issuable_escalation_status, :paging, issue: issue) }
              let(:expected_policy) { nil }

              include_examples 'updates the escalation status record' do
                let(:expected_policy) { nil }
                let(:expected_status) { :triggered }
              end

              context 'in addition to other attributes' do
                let(:opts) { { escalation_status: { policy: policy, status: 'acknowledged' } } }

                include_examples 'updates the escalation status record' do
                  let(:expected_policy) { nil }
                  let(:expected_status) { :acknowledged }
                end
              end
            end

            context 'with the policy value defined but unchanged' do
              it_behaves_like 'does not change the status record'
            end
          end
        end

        context 'when issue is not an incident' do
          it_behaves_like 'does not change the status record'
        end
      end

      context 'without an existing escalation status record' do
        context 'when incident has an associated alert' do
          let!(:alert) { create(:alert_management_alert, :acknowledged, :with_incident, project: project) }
          let(:issue) { alert.issue }

          context 'setting the status' do
            let(:opts) { { escalation_status: { status: :resolved } } }

            include_examples 'updates the escalation status record' do
              let(:expected_policy) { policy }
              let(:expected_status) { :resolved }
            end
          end

          context 'unsetting the policy' do
            let(:opts) { { escalation_status: { policy: nil } } }

            it_behaves_like 'does not change the status record'
          end
        end

        context 'when incident has no associated alert' do
          let(:issue) { create(:incident, project: project) }

          include_examples 'updates the escalation status record' do
            let(:expected_policy) { policy }
            let(:expected_status) { :triggered }
          end
        end
      end
    end

    it_behaves_like 'existing issuable with scoped labels' do
      let(:issuable) { issue }
      let(:parent) { project }
    end

    it_behaves_like 'issue with epic_id parameter' do
      let(:execute) { described_class.new(project: project, current_user: user, params: params).execute(issue) }
    end

    context 'when epic_id is nil' do
      before do
        stub_licensed_features(epics: true)
        group.add_maintainer(user)
        issue.update!(epic: epic)
      end

      let(:epic_issue) { issue.epic_issue }
      let(:params) { { epic_id: nil } }

      subject { update_issue(params) }

      it 'removes epic issue link' do
        expect { subject }.to change { issue.reload.epic }.from(epic).to(nil)
      end

      it 'calls EpicIssues::DestroyService' do
        link_sevice = double
        expect(EpicIssues::DestroyService).to receive(:new).with(epic_issue, user).and_return(link_sevice)
        expect(link_sevice).to receive(:execute).and_return({ status: :success })

        subject
      end
    end

    context 'promoting to epic' do
      before do
        stub_licensed_features(epics: true)
        group.add_developer(user)
      end

      context 'when promote_to_epic param is present' do
        it 'promotes issue to epic' do
          expect { update_issue(promote_to_epic: true) }.to change { Epic.count }.by(1)
          expect(issue.promoted_to_epic_id).not_to be_nil
        end
      end

      context 'when promote_to_epic param is not present' do
        it 'does not promote issue to epic' do
          expect { update_issue(promote_to_epic: false) }.not_to change { Epic.count }
          expect(issue.promoted_to_epic_id).to be_nil
        end
      end
    end

    describe 'publish to status page' do
      let(:execute) { update_issue(params) }
      let(:issue_id) { execute&.id }

      before do
        create(:status_page_published_incident, issue: issue)
      end

      context 'when update succeeds' do
        let(:params) { { title: 'New title' } }

        include_examples 'trigger status page publish'
      end

      context 'when closing' do
        let(:params) { { state_event: 'close' } }

        include_examples 'trigger status page publish'
      end

      context 'when reopening' do
        let(:issue) { create(:issue, :closed, project: project) }
        let(:params) { { state_event: 'reopen' } }

        include_examples 'trigger status page publish'
      end

      context 'when update fails' do
        let(:params) { { title: nil } }

        include_examples 'no trigger status page publish'
      end
    end

    describe 'sync Requirement work item with Requirement object' do
      let_it_be(:title) { 'title' }
      let_it_be(:description) { 'description' }
      let_it_be(:new_title) { 'new title' }
      let_it_be(:new_description) { 'new description' }

      let_it_be_with_reload(:issue) { create(:issue, issue_type: :requirement, project: project, title: title, description: description) }

      let(:params) do
        { state: :closed, title: new_title, description: new_description }
      end

      subject { update_issue(params) }

      shared_examples 'keeps issue and its requirement in sync' do
        it 'keeps title and description in sync' do
          subject

          requirement.reload
          issue.requirement.reload

          expect(requirement).to have_attributes(
            title: issue.requirement.title,
            description: issue.requirement.description)
        end
      end

      shared_examples 'does not persist any changes' do
        it 'does not update the issue' do
          expect { subject }.not_to change { issue.reload.attributes }
        end

        it 'does not update the requirement' do
          expect { subject }.not_to change { requirement.reload.attributes }
        end
      end

      before do
        issue.requirement_sync_error = false
        issue.clear_spam_flags!
      end

      context 'if there is an associated requirement' do
        let_it_be_with_reload(:requirement) { create(:requirement, title: title, description: description, requirement_issue: issue, project: project) }

        it 'updates the mapped field' do
          expect { subject }.to change { requirement.reload.state }.from("opened").to("archived")
        end

        it 'updates the synced requirement with title and/or description' do
          subject

          expect(requirement.reload).to have_attributes(
            title: new_title,
            description: new_description)
        end

        context 'when the issue title is very long' do
          # The Requirement title limit is 255 in the application as well as the DB.
          # The Issue limit is 255 in the application not the DB, so we should be OK.
          # See https://gitlab.com/gitlab-org/gitlab/blob/7a42426/app/models/concerns/issuable.rb#L30
          let_it_be(:new_title) { 'a' * 300 }

          it_behaves_like 'does not persist any changes'
        end

        it_behaves_like 'keeps issue and its requirement in sync'

        context 'if update of issue fails' do
          let(:params) do
            { title: nil }
          end

          it_behaves_like 'keeps issue and its requirement in sync'
          it_behaves_like 'does not persist any changes'
        end

        context 'if update of issue succeeds but update of requirement fails' do
          let(:params) do
            { title: 'some magically valid title for issue but not requirement' }
          end

          before do
            allow(issue).to receive(:requirement).and_return(requirement)
          end

          context 'when requirement is not valid' do
            before do
              expect(requirement).to receive(:valid?).and_return(false).at_least(:once)
            end

            it_behaves_like 'keeps issue and its requirement in sync'
            it_behaves_like 'does not persist any changes'

            it 'adds an informative sync error to issue' do
              subject

              expect(issue.errors[:base]).to include(/Associated requirement/)
            end
          end

          context 'if requirement is valid but still does not save' do
            before do
              allow(issue.requirement).to receive(:valid?).and_return(true).at_least(:once)
              allow(requirement).to receive(:save).and_return(false)
            end

            it 'adds a helpful log' do
              expect(::Gitlab::AppLogger).to receive(:info).with(a_hash_including(message: /Associated requirement/))

              subject
            end
          end
        end

        # spam checking also uses a flag on Issue so we want to ensure they play nicely together
        # If an issue is marked spam, we do not want to try syncing
        # since the issue will not be saved this time (maybe next time if a successful recaptcha has been included)
        context 'if the issue is also marked as spam' do
          before do
            issue.spam!
          end

          it_behaves_like 'keeps issue and its requirement in sync'
          it_behaves_like 'does not persist any changes'

          it 'only shows the spam error' do
            subject

            expect(issue.errors[:base]).to include(/spam/)
            expect(issue.errors[:base]).not_to include(/sync/)
          end
        end
      end

      context 'if there is no associated requirement' do
        it 'does not call the RequirementsManagement::UpdateRequirementService' do
          expect(RequirementsManagement::UpdateRequirementService).not_to receive(:new)

          update_issue(params)
        end
      end
    end
  end
end
