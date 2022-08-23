# frozen_string_literal: true

module Iterations
  module Cadences
    class DestroyService
      include Gitlab::Allowable

      def initialize(iteration_cadence, user)
        @iteration_cadence = iteration_cadence
        @group = iteration_cadence.group
        @current_user = user
      end

      def execute
        response_payload = { group: @group }
        return ::ServiceResponse.error(message: _('Operation not allowed'), payload: response_payload, http_status: 403) unless can_destroy_iteration_cadence?

        if destroy_and_remove_references
          ::ServiceResponse.success(payload: response_payload.merge(iteration_cadence: iteration_cadence))
        else
          ::ServiceResponse.error(message: iteration_cadence.errors.full_messages, payload: response_payload, http_status: 422)
        end
      end

      private

      attr_reader :iteration_cadence, :current_user, :group

      def can_destroy_iteration_cadence?
        group.licensed_feature_available?(:iterations) &&
          can?(current_user, :admin_iteration_cadence, iteration_cadence)
      end

      def destroy_and_remove_references
        ApplicationRecord.transaction do
          Board.in_iteration_cadences(iteration_cadence).update_all(iteration_id: nil, iteration_cadence_id: nil)
          # it may be that a board is scoped to a specific iteration but missing the cadence_id, so we cleanup that one as well
          Board.in_iterations(iteration_cadence.iterations).update_all(iteration_id: nil)

          iteration_cadence.destroy
        end
      end
    end
  end
end
