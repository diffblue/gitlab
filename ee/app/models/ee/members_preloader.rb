# frozen_string_literal: true

module EE
  module MembersPreloader
    extend ::Gitlab::Utils::Override

    override :preload_all
    def preload_all
      super

      ActiveRecord::Associations::Preloader.new.preload(members, user: { group_saml_identities: :saml_provider })
      ActiveRecord::Associations::Preloader.new.preload(members, user: :oncall_schedules)
      ActiveRecord::Associations::Preloader.new.preload(members, user: :escalation_policies)
      ActiveRecord::Associations::Preloader.new.preload(members, user: :user_detail)
      ActiveRecord::Associations::Preloader.new.preload(members, user: :namespace_bans)
    end
  end
end
