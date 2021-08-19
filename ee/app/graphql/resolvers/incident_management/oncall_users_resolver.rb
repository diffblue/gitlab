# frozen_string_literal: true

module Resolvers
  module IncidentManagement
    class OncallUsersResolver < BaseResolver
      alias_method :schedule, :object

      type [::Types::UserType], null: true

      def resolve
        oncall_at = context[:execution_time] || Time.current

        ::IncidentManagement::OncallUsersFinder.new(schedule.project, schedule: schedule, oncall_at: oncall_at).execute
      end
    end
  end
end
