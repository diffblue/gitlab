# frozen_string_literal: true

module Groups
  module EnterpriseUsers
    class AssociateWorker
      include ApplicationWorker

      idempotent!
      feature_category :user_management
      data_consistency :always # rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency

      def perform(user_id)
        user = User.find_by_id(user_id)
        return unless user

        pages_domain = PagesDomain.verified.find_by_domain_case_insensitive(user.email_domain)
        return unless pages_domain

        group = pages_domain.root_group
        return unless group

        return unless Feature.enabled?(:enterprise_users_automatic_claim, group)

        Groups::EnterpriseUsers::AssociateService.new(group: group, user: user).execute
      end
    end
  end
end
