# frozen_string_literal: true

module EE
  module Gitlab
    module RepositorySizeChecker
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      override :above_size_limit?
      def above_size_limit?
        return false unless enabled?
        return false if additional_repo_storage_available? && total_repository_size_excess <= additional_purchased_storage

        super
      end

      override :exceeded_size
      # @param change_size [int] in bytes
      def exceeded_size(change_size = 0)
        size = super
        size -= remaining_additional_purchased_storage if additional_repo_storage_available?

        [size, 0].max
      end

      override :additional_repo_storage_available?
      def additional_repo_storage_available?
        namespace.present? && ::Gitlab::CurrentSettings.automatic_purchased_storage_allocation?
      end

      private

      def total_repository_size_excess
        namespace&.total_repository_size_excess.to_i
      end

      def additional_purchased_storage
        namespace&.additional_purchased_storage_size&.megabytes.to_i
      end

      def current_project_excess
        [current_size - limit, 0].max
      end

      def total_excess_without_current_project
        total_repository_size_excess - current_project_excess
      end

      def remaining_additional_purchased_storage
        [additional_purchased_storage - total_excess_without_current_project, 0].max
      end
    end
  end
end
