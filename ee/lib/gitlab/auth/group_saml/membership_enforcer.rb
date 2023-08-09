# frozen_string_literal: true

module Gitlab
  module Auth
    module GroupSaml
      class MembershipEnforcer
        def initialize(group)
          @group = group
        end

        def can_add_user?(user)
          return true unless root_group.saml_provider&.enforced_sso?
          return true if user.project_bot?

          return false if skip_delete_saml_identity_feature_enabled? && inactive_scim_identity_for_group?(user)

          GroupSamlIdentityFinder.new(user: user).find_linked(group: root_group)
        end

        private

        def skip_delete_saml_identity_feature_enabled?
          Feature.enabled?(:skip_saml_identity_destroy_during_scim_deprovision)
        end

        def root_group
          @root_group ||= @group.root_ancestor
        end

        def inactive_scim_identity_for_group?(user)
          scim_identities = root_group.scim_identities.for_user(user)
          inactive_identities = scim_identities.reject(&:active?)
          inactive_identities.any?
        end
      end
    end
  end
end
