# frozen_string_literal: true

module Namespaces
  module Storage
    class EmailNotificationService
      def initialize(mailer)
        @mailer = mailer
      end

      def execute(namespace)
        return unless namespace.root_storage_statistics

        root_storage_size = ::Namespace::RootStorageSize.new(namespace)
        usage_ratio = root_storage_size.usage_ratio
        level = notification_level(usage_ratio)
        last_level = namespace.root_storage_statistics.notification_level.to_sym

        if level != last_level
          send_notification(level, namespace, usage_ratio)
          update_notification_level(level, namespace)
        end
      end

      private

      attr_reader :mailer

      def notification_level(usage_ratio)
        case usage_ratio
        when 0...0.7 then :storage_remaining
        when 0.7...0.85 then :caution
        when 0.85...0.95 then :warning
        when 0.95...1 then :danger
        when 1..Float::INFINITY then :exceeded
        end
      end

      def send_notification(level, namespace, usage_ratio)
        return if level == :storage_remaining

        owner_emails = namespace.owners.map(&:email)

        if level == :exceeded
          mailer.notify_out_of_storage(namespace, owner_emails)
        else
          percentage = storage_remaining_percentage(usage_ratio)
          mailer.notify_limit_warning(namespace, owner_emails, percentage)
        end
      end

      def update_notification_level(level, namespace)
        namespace.root_storage_statistics.update!(notification_level: level)
      end

      def storage_remaining_percentage(usage_ratio)
        (100 - usage_ratio * 100).floor
      end
    end
  end
end
