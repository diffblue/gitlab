# frozen_string_literal: true

module EE
  module GroupsHelper
    extend ::Gitlab::Utils::Override

    def can_admin_group_protected_branches?(group)
      ::Feature.enabled?(:group_protected_branches) &&
        ::License.feature_available?(:group_protected_branches) &&
        can?(current_user, :admin_group, group) &&
        group.root?
    end

    def size_limit_message_for_group(group)
      show_lfs = group.lfs_enabled? ? 'including LFS files' : ''

      "Max size for repositories within this group #{show_lfs}. Can be overridden inside each project. For no limit, enter 0. To inherit the global value, leave blank."
    end

    override :remove_group_message
    def remove_group_message(group)
      return super unless group.licensed_feature_available?(:adjourned_deletion_for_projects_and_groups)
      return super if group.marked_for_deletion?
      return super unless group.adjourned_deletion?

      date = permanent_deletion_date(Time.now.utc)

      _("The contents of this group, its subgroups and projects will be permanently removed after %{deletion_adjourned_period} days on %{date}. After this point, your data cannot be recovered.") %
        { date: date, deletion_adjourned_period: deletion_adjourned_period }
    end

    def immediately_remove_group_message(group)
      message = _('This action will %{strongOpen}permanently remove%{strongClose} %{codeOpen}%{group}%{codeClose} %{strongOpen}immediately%{strongClose}.')

      html_escape(message) % {
        group: group.path,
        strongOpen: '<strong>'.html_safe,
        strongClose: '</strong>'.html_safe,
        codeOpen: '<code>'.html_safe,
        codeClose: '</code>'.html_safe
      }
    end

    def permanent_deletion_date(date)
      (date + deletion_adjourned_period.days).strftime('%F')
    end

    def deletion_adjourned_period
      ::Gitlab::CurrentSettings.deletion_adjourned_period
    end

    def show_discover_group_security?(group)
      !!current_user &&
        ::Gitlab.com? &&
        !@group.licensed_feature_available?(:security_dashboard) &&
        can?(current_user, :admin_group, @group)
    end

    def show_group_activity_analytics?
      can?(current_user, :read_group_activity_analytics, @group)
    end

    def show_delayed_project_removal_setting?(group)
      group.licensed_feature_available?(:adjourned_deletion_for_projects_and_groups)
    end

    def show_product_purchase_success_alert?
      !params[:purchased_product].blank?
    end

    def group_seats_usage_quota_app_data(group)
      pending_members_page_path = group.user_cap_available? ? pending_members_group_usage_quotas_path(group) : nil
      pending_members_count = ::Member.in_hierarchy(group).with_state("awaiting").count

      {
        namespace_id: group.id,
        namespace_name: group.name,
        seat_usage_export_path: group_seat_usage_path(group, format: :csv),
        pending_members_page_path: pending_members_page_path,
        pending_members_count: pending_members_count,
        add_seats_href: add_seats_url(group),
        has_no_subscription: group.has_free_or_no_subscription?.to_s,
        max_free_namespace_seats: ::Namespaces::FreeUserCap.dashboard_limit,
        explore_plans_path: group_billings_path(group),
        enforcement_free_user_cap_enabled: ::Namespaces::FreeUserCap::Enforcement.new(group).enforce_cap?.to_s,
        notification_free_user_cap_enabled: ::Namespaces::FreeUserCap::Notification.new(group).enforce_cap?.to_s
      }
    end

    def usage_quotas_storage_app_data(group)
      url_to_purchase_storage = buy_storage_path(group) if purchase_storage_link_enabled?(group)
      buy_addon_target_attr = buy_addon_target_attr(group) if purchase_storage_link_enabled?(group)

      {
        namespace_id: group.id,
        namespace_path: group.full_path,
        purchase_storage_url: url_to_purchase_storage,
        buy_addon_target_attr: buy_addon_target_attr,
        default_per_page: page_size,
        storage_limit_enforced: ::EE::Gitlab::Namespaces::Storage::Enforcement.enforce_limit?(group).to_s,
        can_show_inline_alert: project_storage_limit_enforced?(group).to_s,
        additional_repo_storage_by_namespace: group.additional_repo_storage_by_namespace_enabled?.to_s
      }
    end

    def project_storage_limit_enforced?(group)
      group.root_storage_size.enforce_limit? && group.root_storage_size.enforcement_type == :project_repository_limit
    end

    override :require_verification_for_namespace_creation_enabled?
    def require_verification_for_namespace_creation_enabled?
      # Skip the verification for admins and auditors (added mainly for E2E tests)
      return false if current_user.can_read_all_resources?
      # Experiment should only run when creating top-level groups
      return false if params[:parent_id]

      experiment(:require_verification_for_namespace_creation, user: current_user).run
    end

    override :verification_for_group_creation_data
    def verification_for_group_creation_data
      {
        verification_required: require_verification_for_namespace_creation_enabled?.to_s,
        verification_form_url: ::Gitlab::SubscriptionPortal::REGISTRATION_VALIDATION_FORM_URL,
        subscriptions_url: ::Gitlab::SubscriptionPortal::SUBSCRIPTIONS_URL
      }
    end

    def saml_sso_settings_generate_helper_text(display_none:, text:)
      content_tag(:span, text, class: ['js-helper-text', 'gl-clearfix', ('gl-display-none' if display_none)])
    end
  end
end
