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

    def unban
      member = membershipable_members.find(params[:id])

      namespace = member.member_namespace
      ban = member.user.namespace_ban_for(namespace)

      ::Users::Abuse::NamespaceBans::DestroyService.new(ban, current_user).execute

      redirect_to members_page_url, notice: _("User was successfully unbanned.")
    end
  end
end
