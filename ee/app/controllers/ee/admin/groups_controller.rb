# frozen_string_literal: true

# rubocop:disable Gitlab/ModuleWithInstanceVariables
module EE
  module Admin
    module GroupsController
      extend ::Gitlab::Utils::Override

      def reset_runners_minutes
        group

        ::Ci::Minutes::ResetUsageService.new(@group).execute
        redirect_to [:admin, @group], notice: _('Group pipeline minutes were successfully reset.')
      end

      private

      def allowed_group_params
        super + [
          :repository_size_limit,
          :shared_runners_minutes_limit,
          gitlab_subscription_attributes: [:hosted_plan_id]
        ]
      end

      override :group_members
      def group_members
        return @group.all_group_members if @group.minimal_access_role_allowed?

        @group.members
      end

      def groups
        super.with_deletion_schedule
      end
    end
  end
end
