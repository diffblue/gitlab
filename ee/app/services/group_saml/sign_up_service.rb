# frozen_string_literal: true
module GroupSaml
  class SignUpService
    attr_reader :group, :new_user, :oauth_data, :session

    def initialize(new_user, group, session)
      @new_user = new_user
      @group = group
      @oauth_data = session['oauth_data']
      @session = session
    end

    def execute
      ApplicationRecord.transaction do
        new_user.managing_group = group if group.saml_provider&.enforced_group_managed_accounts?

        if new_user.save
          identity_linker = Gitlab::Auth::GroupSaml::IdentityLinker.new(new_user, oauth_data, session, group.saml_provider)
          identity_linker.link
        end

        new_user.persisted? && !identity_linker.failed?
      end
    end
  end
end
