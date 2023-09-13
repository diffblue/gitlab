# frozen_string_literal: true

module EE
  module Members
    module CreatorService
      extend ::Gitlab::Utils::Override

      private

      override :member_attributes
      def member_attributes
        super.merge(ldap: ldap)
      end

      override :after_commit_tasks
      def after_commit_tasks
        super

        finish_onboarding_user
      end

      def finish_onboarding_user
        return unless ::Onboarding.user_onboarding_in_progress?(member.user)
        return unless finished_welcome_step?

        member.user.update(onboarding_step_url: nil, onboarding_in_progress: false)
      end

      def finished_welcome_step?
        member.user.role?
      end
    end
  end
end
