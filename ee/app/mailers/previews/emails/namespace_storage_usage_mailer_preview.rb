# frozen_string_literal: true

module Emails
  class NamespaceStorageUsageMailerPreview < ActionMailer::Preview
    def out_of_storage
      ::Emails::NamespaceStorageUsageMailer.notify_out_of_storage(
        namespace: Group.last,
        recipients: %w(bob@example.com),
        usage_values: {
          current_size: 100.megabytes,
          limit: 101.megabytes,
          used_storage_percentage: 101
        })
    end

    def limit_warning
      ::Emails::NamespaceStorageUsageMailer.notify_limit_warning(
        namespace: Group.last,
        recipients: %w(bob@example.com),
        usage_values: {
          current_size: 74.megabytes,
          limit: 100.megabytes,
          used_storage_percentage: 74
        })
    end
  end
end
