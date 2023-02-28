# frozen_string_literal: true

module EE
  module MembersPreloader
    extend ::Gitlab::Utils::Override

    override :preload_all
    def preload_all
      super

      ActiveRecord::Associations::Preloader.new(
        records: members,
        associations: {
          user: [
            :oncall_schedules,
            :escalation_policies,
            :user_detail,
            :namespace_bans,
            { group_saml_identities: :saml_provider }
          ]
        }
      ).call
    end
  end
end
