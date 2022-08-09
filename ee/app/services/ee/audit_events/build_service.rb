# frozen_string_literal: true
# rubocop:disable Gitlab/ModuleWithInstanceVariables

module EE
  module AuditEvents
    module BuildService
      extend ::Gitlab::Utils::Override

      private

      override :payload
      def payload
        if License.feature_available?(:admin_audit_log)
          base_payload.merge(
            details: base_details_payload.merge(
              ip_address: @ip_address,
              entity_path: @scope.full_path,
              custom_message: @message
            ),
            ip_address: @ip_address
          )
        else
          super
        end
      end

      override :build_message
      def build_message(message)
        if License.feature_available?(:admin_audit_log) && @author.impersonated?
          "#{message} (by #{@author.impersonated_by})"
        else
          super
        end
      end

      override :build_author
      def build_author(author)
        super

        author.impersonated? ? ::Gitlab::Audit::ImpersonatedAuthor.new(author) : author
      end
    end
  end
end
# rubocop:enable Gitlab/ModuleWithInstanceVariables
