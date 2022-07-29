# frozen_string_literal: true

module EE
  module Namespace
    module Storage
      class Notification
        include ::ActiveSupport::NumberHelper
        include ::Gitlab::Utils::StrongMemoize

        def initialize(context, user)
          @context = context
          @root_namespace = context.root_ancestor
          @user = user
          @root_storage_size = root_namespace.root_storage_size
        end

        def show?
          return false unless ::Gitlab::CurrentSettings.should_check_namespace_plan?
          return false unless user.present?
          return false unless user.can?(:maintainer_access, context)
          return false if alert_level == :none

          root_storage_size.enforce_limit?
        end

        def payload
          {
            explanation_message: explanation_message,
            usage_message: usage_message,
            alert_level: alert_level,
            root_namespace: root_namespace
          }
        end

        private

        attr_reader :context, :root_namespace, :root_storage_size, :user

        USAGE_THRESHOLDS = {
          none: 0.0,
          info: 0.5,
          warning: 0.75,
          alert: 0.95,
          error: 1.0
        }.freeze

        def enforcement_type
          @enforcement_type ||= ::Feature.enabled?(:namespace_storage_limit, root_namespace) ? :namespace : :repository
        end

        def alert_level
          strong_memoize(:alert_level) do
            usage_ratio = root_storage_size.usage_ratio
            current_level = USAGE_THRESHOLDS.each_key.first

            USAGE_THRESHOLDS.each do |level, threshold|
              current_level = level if usage_ratio >= threshold
            end

            current_level
          end
        end

        def explanation_message
          root_storage_size.above_size_limit? ? above_size_limit_message : below_size_limit_message
        end

        def usage_message
          if enforcement_type == :repository && root_namespace.contains_locked_projects?
            repository_usage_message
          else
            s_("NamespaceStorageSize|You have reached %{usage_in_percent} of %{namespace_name}'s storage " \
            "capacity (%{used_storage} of %{storage_limit})" % current_usage_params)
          end
        end

        def repository_usage_message
          params = { namespace_name: root_namespace.name,
                    locked_project_count: root_namespace.repository_size_excess_project_count,
                    free_size_limit: formatted(root_namespace.actual_size_limit) }

          if root_namespace.additional_purchased_storage_size == 0
            s_("NamespaceStorageSize|You have reached the free storage limit of %{free_size_limit} " \
              "on one or more projects." % params)
          else
            ns_("NamespaceStorageSize|%{namespace_name} contains %{locked_project_count} locked project",
                "NamespaceStorageSize|%{namespace_name} contains %{locked_project_count} locked projects",
                params[:locked_project_count]) % params
          end
        end

        def below_size_limit_message
          s_("NamespaceStorageSize|If you reach 100%% storage capacity, you will not be able " \
            "to: %{base_message}" % { base_message: base_message } )
        end

        def above_size_limit_message
          if enforcement_type == :repository
            repository_above_size_limit_message
          else
            s_("NamespaceStorageSize|%{namespace_name} is now read-only. " \
              "You cannot: %{base_message}" % { namespace_name: root_namespace.name, base_message: base_message })
          end
        end

        def repository_above_size_limit_message
          params = { base_message: base_message, free_size_limit: formatted(root_namespace.actual_size_limit) }

          if root_namespace.additional_purchased_storage_size > 0
            s_("NamespaceStorageSize|You have consumed all of your additional storage, please purchase " \
              "more to unlock your projects over the free %{free_size_limit} limit. " \
              "You can't %{base_message}" % params)
          else
            s_("NamespaceStorageSize|Please purchase additional storage to unlock your projects over the " \
              "free %{free_size_limit} project limit. You can't %{base_message}" % params)
          end
        end

        def base_message
          s_("NamespaceStorageSize|push to your repository, create pipelines, create issues or add comments. " \
            "To reduce storage capacity, delete unused repositories, artifacts, wikis, issues, and pipelines.")
        end

        def current_usage_params
          {
            usage_in_percent: number_to_percentage(root_storage_size.usage_ratio * 100, precision: 0),
            namespace_name: root_namespace.name,
            used_storage: formatted(root_storage_size.current_size),
            storage_limit: formatted(root_storage_size.limit)
          }
        end

        def formatted(number)
          number_to_human_size(number, delimiter: ',', precision: 2)
        end
      end
    end
  end
end
