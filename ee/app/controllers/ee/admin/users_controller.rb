# frozen_string_literal: true

# rubocop:disable Gitlab/ModuleWithInstanceVariables
module EE
  module Admin
    module UsersController
      extend ::Gitlab::Utils::Override

      def reset_runners_minutes
        user

        ::Ci::Minutes::ResetUsageService.new(@user.namespace).execute
        redirect_to [:admin, @user], notice: _('User pipeline minutes were successfully reset.')
      end

      def card_match
        return render_404 unless ::Gitlab.com?

        credit_card_validation = user.credit_card_validation

        if credit_card_validation&.holder_name
          @similar_credit_card_validations = credit_card_validation.similar_records.page(params[:page]).per(100)
        else
          redirect_to [:admin, @user], notice: _('No credit card data for matching')
        end
      end

      private

      override :users_with_included_associations
      def users_with_included_associations(users)
        super.includes(:oncall_schedules, :escalation_policies, :user_highest_role, :elevated_members) # rubocop: disable CodeReuse/ActiveRecord
      end

      override :log_impersonation_event
      def log_impersonation_event
        super

        log_audit_event
      end

      def log_audit_event
        ::AuditEvents::UserImpersonationEventCreateWorker.perform_async(current_user.id, user.id, request.remote_ip, 'started', DateTime.current)
      end

      def allowed_user_params
        super + [
          namespace_attributes: [
            :id,
            :shared_runners_minutes_limit,
            gitlab_subscription_attributes: [:hosted_plan_id]
          ],
          custom_attributes_attributes: [:id, :value]
        ]
      end
    end
  end
end
