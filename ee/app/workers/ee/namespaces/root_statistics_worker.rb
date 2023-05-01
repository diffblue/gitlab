# frozen_string_literal: true

module EE
  module Namespaces
    module RootStatisticsWorker
      extend ::Gitlab::Utils::Override

      private

      override :notify_storage_usage
      def notify_storage_usage(namespace)
        return unless ::Namespaces::Storage::Enforcement.enforce_limit?(namespace)

        mailer = ::Emails::NamespaceStorageUsageMailer
        ::Namespaces::Storage::EmailNotificationService.new(mailer).execute(namespace)
      end
    end
  end
end
