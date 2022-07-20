# frozen_string_literal: true

module EE
  module Gitlab
    class NamespaceStorageSizeErrorMessage
      include ActiveSupport::NumberHelper

      delegate :current_size, :limit, :exceeded_size, to: :@checker

      def initialize(checker)
        @checker = checker
      end

      def commit_error
        push_error
      end

      def merge_error
        "This merge request cannot be merged, because the namespace storage limit " \
        "of #{formatted(limit)} has been reached."
      end

      def push_error(change_size = 0)
        "Your push to this repository has been rejected because the namespace storage limit " \
        "of #{formatted(limit)} has been reached. " \
        "Reduce your namespace storage or purchase additional storage."
      end

      def new_changes_error
        "Your push to this repository has been rejected because it would exceed " \
        "the namespace storage limit of #{formatted(limit)}. " \
        "Reduce your namespace storage or purchase additional storage."
      end

      def above_size_limit_message
        "The namespace storage size (#{formatted(current_size)}) exceeds the limit of #{formatted(limit)} " \
        "by #{formatted(exceeded_size)}. You won't be able to push new code to this project. " \
        "Please contact your GitLab administrator for more information."
      end

      private

      def formatted(number)
        number_to_human_size(number, delimiter: ',', precision: 2)
      end
    end
  end
end
