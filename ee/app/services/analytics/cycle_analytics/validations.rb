# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    module Validations
      def validate
        unless model == Issue || model == MergeRequest
          return error(:invalid_model)
        end

        unless group.licensed_feature_available?(:cycle_analytics_for_groups)
          return error(:missing_license)
        end

        unless group.root?
          error(:requires_top_level_group)
        end
      end

      def error(error_reason)
        ServiceResponse.error(
          message: "#{self.class.name} error for group: #{group.id} (#{error_reason})",
          payload: { reason: error_reason }
        )
      end

      def success(success_reason, payload = {})
        ServiceResponse.success(payload: { reason: success_reason }.merge(payload))
      end
    end
  end
end
