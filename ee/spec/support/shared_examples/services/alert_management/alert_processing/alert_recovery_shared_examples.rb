# frozen_string_literal: true

# This shared_example requires the following variables:
# - `project`, expected project for an incoming alert
# - `users`, users expected to receive on-call notifications
# - `gitlab_fingerprint`, sha which is used to uniquely identify the alert
RSpec.shared_examples 'oncall users are correctly notified of recovery alert' do
  it_behaves_like 'does not send on-call notification'

  context 'when alert with the same fingerprint already exists' do
    context 'which is triggered' do
      let_it_be(:alert) { create(:alert_management_alert, :triggered, fingerprint: gitlab_fingerprint, project: project) }

      it_behaves_like 'sends on-call notification if enabled'
    end

    context 'which is acknowledged' do
      let_it_be(:alert) { create(:alert_management_alert, :acknowledged, fingerprint: gitlab_fingerprint, project: project) }

      it_behaves_like 'sends on-call notification if enabled'
    end

    context 'which is resolved' do
      let_it_be(:alert) { create(:alert_management_alert, :resolved, fingerprint: gitlab_fingerprint, project: project) }

      it_behaves_like 'does not send on-call notification'
    end

    context 'which is ignored' do
      let_it_be(:alert) { create(:alert_management_alert, :ignored, fingerprint: gitlab_fingerprint, project: project) }

      it_behaves_like 'sends on-call notification if enabled'
    end
  end
end
