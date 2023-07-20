# frozen_string_literal: true

module Groups
  module EnterpriseUsers
    class DisassociateWorker
      include ApplicationWorker

      idempotent!
      feature_category :user_management
      data_consistency :always # rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency

      def perform(user_id)
        user = User.find_by_id(user_id)
        return unless user

        Groups::EnterpriseUsers::DisassociateService.new(user: user).execute
      end
    end
  end
end
