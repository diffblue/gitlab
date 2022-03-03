# frozen_string_literal: true

module EE
  module Ci
    module PipelinesHelper
      def show_cc_validation_alert?(pipeline)
        return false unless ::Gitlab.com?
        return false if pipeline.user.blank? || current_user != pipeline.user

        pipeline.user_not_verified? && !pipeline.user.has_required_credit_card_to_run_pipelines?(pipeline.project)
      end
    end
  end
end
