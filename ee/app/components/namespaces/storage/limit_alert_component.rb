# frozen_string_literal: true

module Namespaces
  module Storage
    class LimitAlertComponent < ViewComponent::Base
      # @param [Namespace, Group or Project] context
      # @param [User] user
      def initialize(context:, user:)
        @context = context
        @root_namespace = context.root_ancestor
        @user = user
        @root_storage_size = root_namespace.root_storage_size
      end

      private

      delegate :sprite_icon, :usage_quotas_path, :buy_storage_path, :purchase_storage_url, to: :helpers
      attr_reader :context, :root_namespace, :user, :root_storage_size

      def render?
        return false unless ::Gitlab::CurrentSettings.should_check_namespace_plan?
        return false unless user.present?
        return false unless user_has_access?
        return false unless root_storage_size.enforce_limit?
        return false if alert_level == :none

        !user_has_dismissed_alert?
      end

      def alert_title
        if enforcement_type == :repository && root_namespace.contains_locked_projects?
          repository_alert_title_locked_projects
        else
          namespace_alert_title
        end
      end

      def alert_message
        if enforcement_type == :repository
          repository_alert_message
        else
          namespace_alert_message
        end.map(&:html_safe)
      end

      def alert_variant
        return :danger if [:alert, :error].include?(alert_level)

        alert_level
      end

      def alert_icon
        [:alert, :error].include?(alert_level) ? 'error' : alert_level.to_s
      end

      def alert_callout_path
        root_namespace.user_namespace? ? callouts_path : group_callouts_path
      end

      def root_namespace_id
        root_namespace.id
      end

      def callout_feature_name
        "namespace_storage_limit_banner_#{alert_level}_threshold"
      end

      def purchase_link
        return unless show_purchase_link?

        buy_storage_path(root_namespace)
      end

      def usage_quotas_link
        usage_quotas_path(root_namespace, anchor: 'storage-quota-tab')
      end

      def content_class
        "container-limited limit-container-width" unless user.layout == "fluid"
      end

      def alert_level
        usage_thresholds = {
          none: 0.0,
          warning: 0.75,
          alert: 0.95,
          error: 1
        }.freeze
        usage_ratio = root_storage_size.usage_ratio
        current_level = usage_thresholds.each_key.first

        usage_thresholds.each do |level, threshold|
          current_level = level if usage_ratio >= threshold
        end

        current_level
      end

      def user_has_access?
        if enforcement_type == :repository || (!context.is_a?(Project) && context.user_namespace?)
          Ability.allowed?(user, :owner_access, context)
        else
          Ability.allowed?(user, :maintainer_access, context)
        end
      end

      def namespace_has_additional_storage_purchased?
        root_namespace.additional_purchased_storage_size > 0
      end

      def user_has_dismissed_alert?
        if root_namespace.user_namespace?
          user.dismissed_callout?(feature_name: callout_feature_name)
        else
          user.dismissed_callout_for_group?(
            feature_name: callout_feature_name,
            group: root_namespace
          )
        end
      end

      def show_purchase_link?
        return false unless ::Gitlab::CurrentSettings.automatic_purchased_storage_allocation?

        Ability.allowed?(user, :owner_access, root_namespace)
      end

      def enforcement_type
        @enforcement_type ||=
          if ::EE::Gitlab::Namespaces::Storage::Enforcement.enforce_limit?(root_namespace)
            :namespace
          else
            :repository
          end
      end

      def repository_alert_title_locked_projects
        params = {
          namespace_name: root_namespace.name,
          locked_project_count: root_namespace.repository_size_excess_project_count,
          free_size_limit: formatted(root_namespace.actual_size_limit)
        }

        if namespace_has_additional_storage_purchased?
          ns_(
            "NamespaceStorageSize|%{namespace_name} contains %{locked_project_count} locked project",
            "NamespaceStorageSize|%{namespace_name} contains %{locked_project_count} locked projects",
            params[:locked_project_count]
          ) % params
        else
          s_(
            "NamespaceStorageSize|You have reached the free storage limit of %{free_size_limit} " \
            "on one or more projects"
          ) % params
        end
      end

      def namespace_alert_title
        current_usage_params = {
          usage_in_percent: number_to_percentage(root_storage_size.usage_ratio * 100, precision: 0),
          namespace_name: root_namespace.name,
          used_storage: formatted(root_storage_size.current_size),
          storage_limit: formatted(root_storage_size.limit)
        }

        s_(
          "NamespaceStorageSize|You have used %{usage_in_percent} of the storage quota for %{namespace_name} " \
          "(%{used_storage} of %{storage_limit})"
        ) % current_usage_params
      end

      def repository_alert_message
        paragraph_1 = repository_alert_message_below_limit
        paragraph_1 = repository_alert_message_above_limit if root_storage_size.above_size_limit?

        [paragraph_1]
      end

      def repository_alert_message_above_limit
        params = {
          repository_limits_description: repository_limits_description,
          free_size_limit: formatted(root_namespace.actual_size_limit)
        }

        if namespace_has_additional_storage_purchased?
          s_(
            "NamespaceStorageSize|You have consumed all of your additional storage, please purchase " \
            "more to unlock your projects over the free %{free_size_limit} limit. " \
            "You can't %{repository_limits_description}"
          ) % params
        else
          s_(
            "NamespaceStorageSize|Please purchase additional storage to unlock your projects over the " \
            "free %{free_size_limit} project limit. You can't %{repository_limits_description}"
          ) % params
        end
      end

      def repository_alert_message_below_limit
        params = {
          repository_limits_description: repository_limits_description
        }

        s_(
          "NamespaceStorageSize|If you reach 100%% storage capacity, you will not be able " \
          "to: %{repository_limits_description}"
        ) % params
      end

      def repository_limits_description
        params = {
          learn_more_link: help_page_link_to(_("Learn more"), 'user/usage_quotas', 'manage-your-storage-usage')
        }

        s_(
          "NamespaceStorageSize|push to your repository, create pipelines, create issues or add comments. " \
          "To reduce storage capacity, delete unused repositories, artifacts, wikis, issues, and pipelines. " \
          "%{learn_more_link}."
        ) % params
      end

      # paragraphs come in an array, then we use `each` to add these paragraphs in haml
      def namespace_alert_message
        params = {
          namespace_name: root_namespace.name,
          learn_more_link: help_page_link_to(_("Learn more"), 'user/usage_quotas', 'manage-your-storage-usage')
        }

        paragraph_1 = namespace_alert_message_below_limit
        paragraph_1 = namespace_alert_message_above_limit if root_storage_size.above_size_limit?

        paragraph_2 = s_(
          "NamespaceStorageSize|Manage your storage usage or, if you are a namespace Owner, " \
          "purchase additional storage. %{learn_more_link}."
        ) % params

        [paragraph_1, paragraph_2]
      end

      def namespace_alert_message_above_limit
        params = {
          namespace_name: root_namespace.name,
          actions_restricted_link: help_page_link_to(
            _("Which actions are restricted?"),
            'user/read_only_namespaces'
          )
        }

        s_(
          "NamespaceStorageSize|%{namespace_name} is now read-only. " \
          "Projects under this namespace are locked and actions are restricted. %{actions_restricted_link}"
        ) % params
      end

      def namespace_alert_message_below_limit
        params = {
          namespace_name: root_namespace.name,
          actions_restricted_link: help_page_link_to(
            _("Which actions become restricted?"),
            'user/read_only_namespaces'
          )
        }

        s_(
          "NamespaceStorageSize|If %{namespace_name} exceeds the storage quota, " \
          "all projects in the namespace will be locked and actions will be restricted. %{actions_restricted_link}"
        ) % params
      end

      def help_page_link_to(name, path, anchor = nil)
        link_to(name, help_page_path(path, anchor: anchor), target: '_blank', rel: "noopener noreferrer")
      end

      def formatted(number)
        number_to_human_size(number, delimiter: ',', precision: 2)
      end
    end
  end
end
