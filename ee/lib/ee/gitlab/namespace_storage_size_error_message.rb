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
        "Your namespace storage is full. This merge request cannot be merged. " \
        "To continue, %{manage_storage_url}.".html_safe % {
          manage_storage_url: link_to(
            'manage your storage usage',
            help_page_path('user/usage_quotas'),
            target: '_blank',
            rel: 'noopener noreferrer'
          )
        }
      end

      def push_error(change_size = 0)
        self.class.storage_limit_reached_error_msg
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

      def self.storage_limit_reached_error_msg
        _(
          "Your action has been rejected because the namespace storage limit has been reached. " \
          "For more information, visit %{doc_url}." % {
            doc_url: Rails.application.routes.url_helpers.help_page_url('user/usage_quotas')
          }
        )
      end

      private

      def formatted(number)
        number_to_human_size(number, delimiter: ',', precision: 2)
      end

      def link_to(text, url, options)
        ActionController::Base.helpers.link_to(text, url, options)
      end

      def help_page_path(path)
        ::Gitlab::Routing.url_helpers.help_page_path(path)
      end
    end
  end
end
