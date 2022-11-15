# frozen_string_literal: true

module GitlabSubscriptions
  module Trials
    class ApplyTrialService
      include ::Gitlab::Utils::StrongMemoize

      def self.execute(args = {})
        instance = new(**args)
        instance.execute
      end

      def initialize(uid:, trial_user_information:)
        @uid = uid
        @trial_user_information = trial_user_information
      end

      def execute
        if valid_to_generate_trial?
          generate_trial
        else
          ServiceResponse.error(message: 'Not valid to generate a trial with current information')
        end
      end

      def valid_to_generate_trial?
        namespace.present? && !namespace.trial?
      end

      private

      attr_reader :uid, :trial_user_information

      def generate_trial
        response = client.generate_trial(uid: uid, trial_user: trial_user_information)

        if response[:success]
          record_onboarding_progress

          ServiceResponse.success
        else
          ServiceResponse.error(message: response.dig(:data, :errors))
        end
      end

      def client
        Gitlab::SubscriptionPortal::Client
      end

      def record_onboarding_progress
        Onboarding::ProgressService.new(namespace).execute(action: :trial_started)
      end

      def namespace
        Namespace.find_by(id: trial_user_information[:namespace_id]) # rubocop: disable CodeReuse/ActiveRecord
      end
      strong_memoize_attr :namespace
    end
  end
end
