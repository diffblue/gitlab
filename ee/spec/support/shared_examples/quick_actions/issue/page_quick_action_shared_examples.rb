# frozen_string_literal: true

# This shared_example requires the following variables:
# - project (required)
# - issue (required)
# - user (required) - developer role by default

RSpec.shared_examples 'page quick action' do
  describe '/page' do
    let_it_be(:escalation_policy) { create(:incident_management_escalation_policy, project: project, name: 'spec policy') }
    let_it_be(:incident, reload: true) { create(:incident, project: project) }
    let_it_be(:escalation_status, reload: true) { create(:incident_management_issuable_escalation_status, issue: incident) }

    context 'when licensed features are disabled' do
      before do
        visit project_issue_path(project, incident)
        wait_for_all_requests
      end

      it 'does not escalate issue' do
        add_note('/page spec policy')

        expect(page).to have_content('Could not apply page command')
      end
    end

    context 'when licensed features are enabled' do
      before do
        stub_licensed_features(oncall_schedules: true, escalation_policies: true)
      end

      context 'when issue is an incident' do
        before do
          visit project_issue_path(project, incident)
          wait_for_all_requests
        end

        it 'starts escalation with the policy' do
          add_note('/page spec policy')

          expect(page).to have_content('Started escalation for this incident.')
          expect(incident.reload.escalation_status.policy).to eq(escalation_policy)
        end

        it 'starts escalation with policy name as case insensitive' do
          add_note('/page SpEc Policy')

          expect(page).to have_content('Started escalation for this incident.')
          expect(incident.reload.escalation_status.policy).to eq(escalation_policy)
        end

        it 'does not escalate when policy does not exist' do
          add_note('/page wrong policy')

          expect(page).to have_content("Policy 'wrong policy' does not exist.")
          expect(incident.reload.escalation_status.policy).to be_nil
        end

        context 'when issue is already escalated' do
          before do
            # Escalate a policy before paging again
            add_note('/page spec policy')
          end

          it 'does not escalate again with same policy' do
            add_note('/page spec policy')

            expect(page).to have_content("This incident is already escalated with 'spec policy'.")
          end
        end

        context 'when issue already has an alert' do
          let_it_be(:alert) { create(:alert_management_alert, issue: incident) }

          it 'starts escalation with the policy' do
            add_note('/page spec policy')

            expect(page).to have_content('Started escalation for this incident.')
            expect(incident.reload.escalation_status.policy).to eq(escalation_policy)
          end
        end

        context 'when user does not have permissions' do
          before do
            project.add_reporter(user)
            visit project_issue_path(project, incident)
            wait_for_all_requests
          end

          it 'does not escalate incident' do
            add_note('/page spec policy')

            expect(page).to have_content('Could not apply page command')
          end
        end
      end

      context 'when issue is not an incident' do
        it 'does not escalate issue' do
          add_note('/page spec policy')

          expect(page).to have_content('Could not apply page command')
        end
      end
    end
  end
end
