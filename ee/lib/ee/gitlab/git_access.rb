# frozen_string_literal: true

module EE
  module Gitlab
    module GitAccess
      prepend GeoGitAccess
      extend ::Gitlab::Utils::Override
      include PathLocksHelper
      include SubscribableBannerHelper

      override :check
      def check(cmd, changes)
        check_maintenance_mode!(cmd)
        check_geo_license!
        check_smartcard_access!
        check_otp_session!

        super
      end

      override :can_read_project?
      def can_read_project?
        return true if geo?

        super
      end

      override :check_project_accessibility!
      def check_project_accessibility!
        super

        # Deploy keys and tokens are unique in that we don't check
        # against the project policy, where IP restrictions normally are
        # checked. The existence of a project's associated key or
        # token is enough to authenticate read access. To ensure deploy keys
        # and tokens honor the IP allow list, we need to force a check here. We
        # don't want to do this for all Git access because GitLab admin users
        # aren't subject to this IP restriction, but deploy keys and tokens don't
        # necessarily have an associated user.
        return unless deploy_key? || deploy_token?

        raise ::Gitlab::GitAccess::NotFoundError, not_found_message if ip_restricted?
      end

      def group?
        # Strict nil check, to avoid any surprises with Object#present?
        # which can delegate to #empty?
        !group.nil?
      end

      def group
        container if container.is_a?(::Group)
      end

      protected

      override :user
      def user
        return if geo?

        super
      end

      private

      def ip_restricted?
        !::Gitlab::IpRestriction::Enforcer.new(project.group).allows_current_ip? if project.group
      end

      override :check_custom_action
      def check_custom_action
        geo_custom_action || super
      end

      override :check_for_console_messages
      def check_for_console_messages
        super.push(
          *current_replication_lag_message
        )
      end

      override :check_download_access!
      def check_download_access!
        return if geo?

        super
      end

      override :check_change_access!
      def check_change_access!
        check_size_before_push!

        check_if_license_blocks_changes!

        super

        check_push_size!
      end

      override :check_active_user!
      def check_active_user!
        return if geo?

        super
      end

      override :check_additional_conditions!
      def check_additional_conditions!
        check_sso_session!

        super
      end

      def check_geo_license!
        if ::Gitlab::Geo.secondary? && !::Gitlab::Geo.license_allows?
          raise ::Gitlab::GitAccess::ForbiddenError, 'Your current license does not have GitLab Geo add-on enabled.'
        end
      end

      def check_smartcard_access!
        unless can_access_without_new_smartcard_login?
          raise ::Gitlab::GitAccess::ForbiddenError, 'Project requires smartcard login. Please login to GitLab using a smartcard.'
        end
      end

      def check_otp_session!
        return unless ::License.feature_available?(:git_two_factor_enforcement)
        return unless ::Feature.enabled?(:two_factor_for_cli)
        return unless ssh?
        return if !key? || deploy_key?
        return unless user.two_factor_enabled?

        if ::Gitlab::Auth::Otp::SessionEnforcer.new(actor).access_restricted?
          message = "OTP verification is required to access the repository.\n\n"\
          "   Use: #{build_ssh_otp_verify_command}"

          raise ::Gitlab::GitAccess::ForbiddenError, message
        end
      end

      def check_sso_session!
        return true unless user && container
        return if request_from_ci_build?

        return unless ::Gitlab::Auth::GroupSaml::SessionEnforcer.new(user, containing_group).access_restricted?

        root_group = containing_group.root_ancestor
        group_saml_url = Rails.application.routes.url_helpers.sso_group_saml_providers_url(root_group, token: root_group.saml_discovery_token)
        raise ::Gitlab::GitAccess::ForbiddenError, "Cannot find valid SSO session. Please login via your group's SSO at #{group_saml_url}"
      end

      def build_ssh_otp_verify_command
        user = "#{::Gitlab.config.gitlab_shell.ssh_user}@" unless ::Gitlab.config.gitlab_shell.ssh_user.empty?
        user_host = "#{user}#{::Gitlab.config.gitlab_shell.ssh_host}"

        if ::Gitlab.config.gitlab_shell.ssh_port != 22
          "ssh #{user_host} -p #{::Gitlab.config.gitlab_shell.ssh_port} 2fa_verify"
        else
          "ssh #{user_host} 2fa_verify"
        end
      end

      def check_maintenance_mode!(cmd)
        return unless cmd == 'git-receive-pack'
        return unless ::Gitlab.maintenance_mode?

        raise ::Gitlab::GitAccess::ForbiddenError, 'Git push is not allowed because this GitLab instance is currently in (read-only) maintenance mode.'
      end

      def can_access_without_new_smartcard_login?
        return true unless user

        !::Gitlab::Auth::Smartcard::SessionEnforcer.new.access_restricted?(user)
      end

      def geo?
        actor == :geo
      end

      def check_if_license_blocks_changes!
        if ::License.block_changes?
          message = license_message(signed_in: true, is_admin: (user && user.admin?), force_notification: true)
          raise ::Gitlab::GitAccess::ForbiddenError, strip_tags(message)
        end
      end

      def strip_tags(html)
        Rails::Html::FullSanitizer.new.sanitize(html)
      end

      override :check_size_limit?
      def check_size_limit?
        strong_memoize(:check_size_limit) do
          size_checker.enabled? && super
        end
      end

      def containing_group
        return group if group?
        return project.group if project?
      end
    end
  end
end
