# frozen_string_literal: true

module Registrations::ApplyTrial
  extend ActiveSupport::Concern

  included do
    private

    def apply_trial
      apply_trial_params = {
        uid: current_user.id,
        trial_user: params.permit(:glm_source, :glm_content).merge({
                                                                     namespace_id: @group.id,
                                                                     gitlab_com_trial: true,
                                                                     sync_to_gl: true
                                                                   })
      }

      result = GitlabSubscriptions::ApplyTrialService.new.execute(apply_trial_params)
      flash.now[:alert] = result&.dig(:errors) unless result&.dig(:success)

      result&.dig(:success)
    end
  end
end
