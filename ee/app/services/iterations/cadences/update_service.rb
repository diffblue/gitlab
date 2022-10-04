# frozen_string_literal: true

module Iterations
  module Cadences
    class UpdateService
      include Gitlab::Allowable

      def initialize(iteration_cadence, user, params = {})
        @iteration_cadence = iteration_cadence
        @current_user = user
        @params = params.dup
      end

      def execute
        return ::ServiceResponse.error(message: _('Operation not allowed'), http_status: 403) unless can_update_iteration_cadence?

        if iteration_cadence.update(params)
          ::ServiceResponse.success(payload: { iteration_cadence: iteration_cadence })
        else
          ::ServiceResponse.error(message: iteration_cadence.errors.full_messages, http_status: 422)
        end
      end

      private

      attr_reader :iteration_cadence, :params, :current_user

      def can_update_iteration_cadence?
        group = iteration_cadence.group

        group.licensed_feature_available?(:iterations) &&
          can?(current_user, :admin_iteration_cadence, iteration_cadence)
      end
    end
  end
end
