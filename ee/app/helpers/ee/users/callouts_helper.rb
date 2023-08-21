# frozen_string_literal: true

module EE
  module Users
    module CalloutsHelper
      extend ::Gitlab::Utils::Override

      TWO_FACTOR_AUTH_RECOVERY_SETTINGS_CHECK = 'two_factor_auth_recovery_settings_check'
      ACTIVE_USER_COUNT_THRESHOLD = 'active_user_count_threshold'
      GEO_ENABLE_HASHED_STORAGE = 'geo_enable_hashed_storage'
      GEO_MIGRATE_HASHED_STORAGE = 'geo_migrate_hashed_storage'
      ULTIMATE_TRIAL = 'ultimate_trial'
      NEW_USER_SIGNUPS_CAP_REACHED = 'new_user_signups_cap_reached'
      PERSONAL_ACCESS_TOKEN_EXPIRY = 'personal_access_token_expiry'
      EOA_BRONZE_PLAN_BANNER = 'eoa_bronze_plan_banner'
      EOA_BRONZE_PLAN_END_DATE = '2022-01-26'
      CL_SUBSCRIPTION_ACTIVATION = 'cloud_licensing_subscription_activation_banner'
      PROFILE_PERSONAL_ACCESS_TOKEN_EXPIRY = 'profile_personal_access_token_expiry'

      def show_enable_hashed_storage_warning?
        return if hashed_storage_enabled?

        !user_dismissed?(GEO_ENABLE_HASHED_STORAGE)
      end

      def show_migrate_hashed_storage_warning?
        return unless hashed_storage_enabled?
        return if user_dismissed?(GEO_MIGRATE_HASHED_STORAGE)

        any_project_not_in_hashed_storage?
      end

      override :render_dashboard_ultimate_trial
      def render_dashboard_ultimate_trial(user)
        return unless show_ultimate_trial?(user, ULTIMATE_TRIAL) &&
          user_default_dashboard?(user) &&
          !user.owns_paid_namespace? &&
          user.owns_group_without_trial?

        render 'shared/ultimate_trial_callout_content'
      end

      def render_two_factor_auth_recovery_settings_check
        return unless current_user &&
          ::Gitlab.com? &&
          current_user.two_factor_otp_enabled? &&
          !user_dismissed?(TWO_FACTOR_AUTH_RECOVERY_SETTINGS_CHECK, 3.months.ago)

        render 'shared/two_factor_auth_recovery_settings_check'
      end

      def show_profile_token_expiry_notification?
        !user_dismissed?(PROFILE_PERSONAL_ACCESS_TOKEN_EXPIRY, 1.day.ago)
      end

      def show_new_user_signups_cap_reached?
        return false unless current_user&.can_admin_all_resources?
        return false if user_dismissed?(NEW_USER_SIGNUPS_CAP_REACHED)

        new_user_signups_cap = ::Gitlab::CurrentSettings.current_application_settings.new_user_signups_cap
        return false if new_user_signups_cap.nil?

        new_user_signups_cap.to_i <= ::User.billable.count
      end

      def show_eoa_bronze_plan_banner?(namespace)
        return false unless ::Feature.enabled?(:show_billing_eoa_banner)
        return false unless Date.current < eoa_bronze_plan_end_date
        return false unless namespace.bronze_plan?
        return false if user_dismissed?(EOA_BRONZE_PLAN_BANNER)

        (namespace.group_namespace? && namespace.has_owner?(current_user.id)) || !namespace.group_namespace?
      end

      override :dismiss_two_factor_auth_recovery_settings_check
      def dismiss_two_factor_auth_recovery_settings_check
        ::Users::DismissCalloutService.new(
          container: nil, current_user: current_user, params: { feature_name: TWO_FACTOR_AUTH_RECOVERY_SETTINGS_CHECK }
        ).execute
      end

      def show_verification_reminder?
        return false unless ::Gitlab.com?
        return false unless ::Feature.enabled?(:verification_reminder)
        return false unless current_user
        return false if current_user.has_valid_credit_card?

        failed_pipeline = current_user.pipelines.user_not_verified.last
        failed_pipeline.present? && !user_dismissed?('verification_reminder', failed_pipeline.created_at)
      end

      private

      override :dismissed_callout?
      def dismissed_callout?(object, query)
        return super if object.is_a?(Project)

        current_user.dismissed_callout_for_group?(group: object, **query)
      end

      def eoa_bronze_plan_end_date
        Date.parse(EOA_BRONZE_PLAN_END_DATE)
      end

      def hashed_storage_enabled?
        ::Gitlab::CurrentSettings.current_application_settings.hashed_storage_enabled
      end

      def any_project_not_in_hashed_storage?
        ::Project.with_unmigrated_storage.exists?
      end

      def show_ultimate_trial?(user, callout = ULTIMATE_TRIAL)
        return false unless user
        return false unless show_ultimate_trial_suitable_env?
        return false if user_dismissed?(callout)

        true
      end

      def show_ultimate_trial_suitable_env?
        ::Gitlab.com? && !::Gitlab::Database.read_only?
      end
    end
  end
end
