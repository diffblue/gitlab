# frozen_string_literal: true

module GroupSaml
  module SamlProvider
    class BaseService
      extend FastGettext::Translation

      attr_reader :saml_provider, :params, :current_user

      delegate :group, to: :saml_provider

      AUDIT_LOG_ALLOWLIST = %w[
        enabled certificate_fingerprint sso_url enforced_sso enforced_group_managed_accounts prohibited_outer_forks default_membership_role git_check_enforced
      ].freeze

      def initialize(current_user, saml_provider, params:)
        @saml_provider = saml_provider
        @current_user = current_user
        @params = params
      end

      def execute
        ::SamlProvider.transaction do
          group_managed_accounts_was_enforced = saml_provider.enforced_group_managed_accounts?

          updated = saml_provider.update(params)

          if updated && saml_provider.enforced_group_managed_accounts? && !group_managed_accounts_was_enforced
            require_linked_saml_to_enable_group_managed!
          end
        end

        saml_provider.previous_changes.each do |attribute, changes|
          next unless AUDIT_LOG_ALLOWLIST.include?(attribute)

          audit_context = {
            name: audit_name,
            author: current_user,
            scope: saml_provider.group,
            target: saml_provider.group,
            message: message(attribute, changes)
          }

          ::Gitlab::Audit::Auditor.audit(audit_context)
        end
      end

      def audit_name
        "group_saml_provider"
      end

      private

      def require_linked_saml_to_enable_group_managed!
        return if saml_provider.identities.for_user(current_user).exists?

        add_error!(_("Group Owner must have signed in with SAML before enabling Group Managed Accounts"))
      end

      def add_error!(message)
        saml_provider.errors.add(:base, message)

        raise ActiveRecord::Rollback
      end

      def message(attribute, changes)
        change_text = if changes[0].nil?
                        "#{attribute} changed to #{changes[1]}. "
                      else
                        "#{attribute} changed from #{changes[0]} to #{changes[1]}. "
                      end

        "Group SAML SSO configuration changed: #{change_text}"
      end
    end
  end
end
