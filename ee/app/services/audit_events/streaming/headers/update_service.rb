# frozen_string_literal: true
module AuditEvents
  module Streaming
    module Headers
      class UpdateService < Base
        def execute
          super

          header = params[:header]
          return header_error if header.blank?

          audit_message = audit_message(header.key, params[:key])

          if header.update(key: params[:key], value: params[:value])
            audit(action: :update, header: header, message: audit_message)
            ServiceResponse.success(payload: { header: header, errors: [] })
          else
            ServiceResponse.error(message: Array(header.errors))
          end
        end

        private

        def header_error
          ServiceResponse.error(message: "missing header param")
        end

        def audit_message(old_key, new_key)
          if old_key == new_key
            "Updated a custom HTTP header with key #{new_key} to have a new value."
          else
            "Updated a custom HTTP header from key #{old_key} to have a key #{new_key}."
          end
        end
      end
    end
  end
end
