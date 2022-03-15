# frozen_string_literal: true

module Emails
  class NamespaceStorageUsageMailerPreview < ActionMailer::Preview
    def out_of_storage
      ::Emails::NamespaceStorageUsageMailer.notify_out_of_storage(Group.last, %w(bob@example.com))
    end

    def limit_warning
      ::Emails::NamespaceStorageUsageMailer.notify_limit_warning(Group.last, %w(bob@example.com), 25)
    end
  end
end
