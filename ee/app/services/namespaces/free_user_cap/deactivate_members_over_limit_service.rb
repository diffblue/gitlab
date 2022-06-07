# frozen_string_literal: true

# Deactivate Members by setting to `awaiting` state
module Namespaces
  module FreeUserCap
    class DeactivateMembersOverLimitService
      BATCH_SIZE = 100

      def initialize(namespace)
        @namespace = namespace
      end

      def execute
        return unless namespace

        deactivate_memberships
        log_event

      rescue StandardError => ex
        log_error(ex)
      end

      private

      attr_reader :namespace

      # rubocop: disable CodeReuse/ActiveRecord
      def deactivate_memberships
        namespace
          .memberships_to_be_deactivated
          .pluck(:id, :user_id)
          .each_slice(BATCH_SIZE) do |slice|
          ids = slice.map(&:first)
          user_ids = slice.map(&:second)
          Member
            .where(id: ids)
            .update_all(state: ::Member::STATE_AWAITING)

          unique_user_ids = user_ids.uniq
          UserProjectAccessChangedService.new(unique_user_ids)
            .execute(blocking: false,
                     priority: UserProjectAccessChangedService::MEDIUM_PRIORITY)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def log_event
        log_params = {
          namespace: namespace.id,
          message: 'Deactivated all members over the free user limit'
        }

        Gitlab::AppLogger.info(log_params)
      end

      def log_error(ex)
        log_params = {
          namespace: namespace.id,
          message: 'An error has occurred',
          details: ex.message
        }

        Gitlab::AppLogger.error(log_params)
      end
    end
  end
end
