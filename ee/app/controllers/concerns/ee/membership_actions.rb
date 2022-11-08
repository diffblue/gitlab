# frozen_string_literal: true

module EE
  module MembershipActions
    extend ::Gitlab::Utils::Override

    override :leave
    def leave
      super

      if current_user.authorized_by_provisioning_group?(membershipable)
        sign_out current_user
      end
    end
  end
end
