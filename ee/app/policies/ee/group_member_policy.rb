# frozen_string_literal: true

module EE
  module GroupMemberPolicy
    extend ActiveSupport::Concern

    prepended do
      with_scope :subject
      condition(:ldap, score: 0) { @subject.ldap? }

      with_scope :subject
      condition(:override, score: 0) { @subject.override? }

      rule { ~ldap }.prevent :override_group_member
      rule { ldap & ~override }.prevent :update_group_member
    end
  end
end
