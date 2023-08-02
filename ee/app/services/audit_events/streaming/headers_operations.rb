# frozen_string_literal: true

module AuditEvents
  module Streaming
    module HeadersOperations
      def create_header(destination, key, value)
        header = destination.headers.new(key: key, value: value)

        if header.save
          audit_message = "Created custom HTTP header with key #{key}."
          audit(action: :create, header: header, message: audit_message)

          ServiceResponse.success(payload: { header: header, errors: [] })
        else
          ServiceResponse.error(message: Array(header.errors))
        end
      end

      def update_header(header, key, value)
        if header.update(key: key, value: value)
          log_update_audit_event(header)
          ServiceResponse.success(payload: { header: header, errors: [] })
        else
          ServiceResponse.error(message: Array(header.errors))
        end
      end

      def destroy_header(header)
        if header.destroy
          audit_message = "Destroyed a custom HTTP header with key #{header.key}."
          audit(action: :destroy, header: header, message: audit_message)

          ServiceResponse.success
        else
          ServiceResponse.error(message: Array(header.errors))
        end
      end

      private

      def log_update_audit_event(header)
        return if header.previous_changes.except(:updated_at).empty?

        audit(action: :update, header: header, message: update_audit_message(header))
      end

      def update_audit_message(header)
        changes = header.previous_changes.except(:updated_at)
        if changes.key?(:key)
          "Updated a custom HTTP header from key #{changes[:key].first} to have a key #{changes[:key].last}."
        else
          "Updated a custom HTTP header with key #{header.key} to have a new value."
        end
      end
    end
  end
end
