# frozen_string_literal: true

module Types
  class MemberAccessLevelNameEnum < BaseEnum
    graphql_name 'MemberAccessLevelName'
    description 'Name of access levels of a group or project member'

    Gitlab::Access.sym_options_with_owner.each_key do |access_level|
      value access_level.upcase, value: access_level.to_s, description: "#{access_level.to_s.titleize} access."
    end
  end
end
