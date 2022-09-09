# frozen_string_literal: true

module GitlabSubscriptions
  class ApplyTrialService
    def execute(uid:, trial_user:)
      response = client.generate_trial(uid: uid, trial_user: trial_user)

      if response[:success]
        namespace_id = trial_user[:namespace_id]
        record_onboarding_progress(namespace_id) if namespace_id

        { success: true }
      else
        { success: false, errors: response.dig(:data, :errors) }
      end
    end

    private

    def client
      Gitlab::SubscriptionPortal::Client
    end

    def record_onboarding_progress(namespace_id)
      namespace = Namespace.find_by(id: namespace_id) # rubocop: disable CodeReuse/ActiveRecord
      return unless namespace

      Onboarding::ProgressService.new(namespace).execute(action: :trial_started)
    end
  end
end
