# frozen_string_literal: true
module Namespaces
  module Storage
    class CliNotification < EE::Namespace::Storage::Notification
      extend ::Gitlab::Utils::Override

      override :show?
      def show?
        super && (alert_level == :alert || enforcement_type == :repository)
      end

      override :payload
      def payload
        if enforcement_type == :repository
          repository_cli_message
        else
          namespace_cli_message
        end
      end

      private

      def repository_cli_message
        [
          "##### #{alert_level.to_s.upcase} #####",
          "#{usage_message}.",
          repository_explanation_message[:main][:text]
        ].join("\n")
      end

      def namespace_cli_message
        [
          "##### WARNING #####",
          "#{usage_message}.",
          namespace_cli_message_explanation
        ].join("\n")
      end

      def namespace_cli_message_params
        {
          namespace_name: root_namespace.name,
          manage_storage_url: help_page_url('user/usage_quotas', 'manage-your-storage-usage'),
          restricted_actions_url: help_page_url('user/read_only_namespaces', 'restricted-actions')
        }
      end

      def namespace_cli_message_explanation
        _("If %{namespace_name} exceeds the storage quota, " \
          "all projects in the namespace will be locked " \
          "and actions will be restricted. " \
          "To manage storage, or purchase additional storage, see %{manage_storage_url}. " \
          "To learn more about restricted actions, see %{restricted_actions_url}") % namespace_cli_message_params
      end

      def help_page_url(path, anchor = nil)
        ::Gitlab::Routing.url_helpers.help_page_url(path, anchor: anchor)
      end
    end
  end
end
