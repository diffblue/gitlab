# frozen_string_literal: true

module Users
  module Abuse
    module NamespaceBans
      class DestroyService < BaseService
        def initialize(namespace_ban, current_user)
          @namespace_ban = namespace_ban
          @current_user = current_user
        end

        def execute
          return error_no_permissions unless allowed?

          if namespace_ban.destroy
            success
          else
            error(namespace_ban.errors.full_messages.to_sentence)
          end
        end

        private

        attr_reader :namespace_ban

        def allowed?
          current_user&.can?(:owner_access, namespace_ban.namespace)
        end

        def error(message)
          ServiceResponse.error(message: message, payload: { namespace_ban: namespace_ban })
        end

        def success
          ServiceResponse.success(payload: { namespace_ban: namespace_ban })
        end

        def error_no_permissions
          error(_('You have insufficient permissions to remove this Namespace Ban'))
        end
      end
    end
  end
end
