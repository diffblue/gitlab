# frozen_string_literal: true

module Namespaces
  module Storage
    class RepositoryLimitAlertComponent < LimitAlertComponent
      def usage_percentage_alert_title
        text_args = {
          usage_in_percent: used_storage_percentage(root_storage_size.usage_ratio),
          namespace_name: root_namespace.name
        }

        if root_storage_size.above_size_limit?
          s_(
            "NamespaceStorageSize|You have used all available storage for %{namespace_name}"
          ) % text_args
        else
          s_(
            "NamespaceStorageSize|You have used %{usage_in_percent} of the purchased storage for %{namespace_name}"
          ) % text_args
        end
      end

      def free_tier_alert_title
        text_args = {
          readonly_project_count: root_namespace.repository_size_excess_project_count,
          free_size_limit: formatted(root_namespace.actual_size_limit)
        }

        ns_(
          "NamespaceStorageSize|You have reached the free storage limit of %{free_size_limit} on " \
          "%{readonly_project_count} project",
          "NamespaceStorageSize|You have reached the free storage limit of %{free_size_limit} on " \
          "%{readonly_project_count} projects",
          text_args[:readonly_project_count]
        ) % text_args
      end

      def alert_message_explanation
        text_args = {
          free_size_limit: formatted(root_namespace.actual_size_limit)
        }

        if root_storage_size.above_size_limit?
          Kernel.format(
            s_(
              "NamespaceStorageSize|You have consumed all available storage and you can't " \
              "push or add large files to projects over the free tier limit (%{free_size_limit})."
            ),
            text_args
          ).html_safe
        else
          Kernel.format(
            s_(
              "NamespaceStorageSize|If a project reaches 100%% of the storage quota (%{free_size_limit}) " \
              "the project will be in a read-only state, and you won't be able to push to " \
              "your repository or add large files."
            ),
            text_args
          ).html_safe
        end
      end

      def alert_message_cta
        text_args = {
          group_member_link_start: link_start_tag(group_group_members_path(root_namespace)),
          purchase_more_link_start: link_start_tag(
            help_page_path('subscriptions/gitlab_com/index.md', anchor: 'purchase-more-storage-and-transfer')
          ),
          link_end: "</a>"
        }

        if root_storage_size.above_size_limit?
          if Ability.allowed?(user, :owner_access, context)
            return Kernel.format(
              s_(
                "NamespaceStorageSize|To remove the read-only state, reduce git repository and git LFS storage, " \
                "or %{purchase_more_link_start}purchase more storage%{link_end}."
              ),
              text_args
            ).html_safe
          end

          Kernel.format(
            s_(
              "NamespaceStorageSize|To remove the read-only state, reduce git repository and git LFS storage, " \
              "or contact a user with the %{group_member_link_start}owner role for this namespace%{link_end}  " \
              "and ask them to %{purchase_more_link_start}purchase more storage%{link_end}."
            ),
            text_args
          ).html_safe
        else
          s_("NamespaceStorageSize|To reduce storage usage, reduce git repository and git LFS storage.")
        end
      end
    end
  end
end
