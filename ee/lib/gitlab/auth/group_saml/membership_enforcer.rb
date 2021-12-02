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

          GroupSamlIdentityFinder.new(user: user).find_linked(group: root_group)
        end

        private

        def root_group
          @root_group ||= @group.root_ancestor
        end
      end
    end
  end
end
