# frozen_string_literal: true

module Namespaces
  module Storage
    class RootExcessSize
      include ::Gitlab::Utils::StrongMemoize

      attr_reader :root_namespace

      def initialize(root_namespace)
        @root_namespace = root_namespace.root_ancestor # just in case the true root isn't passed
      end

      def above_size_limit?
        return false unless enforce_limit?

        current_size > limit
      end

      def usage_ratio
        return 1 if limit == 0 && current_size > 0
        return 0 if limit == 0

        BigDecimal(current_size) / BigDecimal(limit)
      end

      def current_size
        root_namespace.total_repository_size_excess
      end
      strong_memoize_attr :current_size

      def exceeded_size(change_size = 0)
        exceeded_size = current_size + change_size - limit

        [exceeded_size, 0].max
      end

      def limit
        # https://docs.gitlab.com/ee/user/usage_quotas#project-storage-limit
        root_namespace.additional_purchased_storage_size.megabytes
      end
      strong_memoize_attr :limit

      def enforce_limit?
        ::Gitlab::CurrentSettings.automatic_purchased_storage_allocation?
      end

      def error_message
        message_params = { namespace_name: root_namespace.name }

        @error_message_object ||= ::Gitlab::RootExcessSizeErrorMessage.new(self, message_params)
      end

      def enforcement_type
        :project_repository_limit
      end
    end
  end
end
