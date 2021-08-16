# frozen_string_literal: true

module Resolvers
  module IncidentManagement
    class OncallUsersResolver < BaseResolver
      alias_method :schedule, :object

      type [::Types::UserType], null: true

      def resolve
        ::IncidentManagement::OncallUsersFinder.new(schedule.project, schedule: schedule).execute
      end
    end
  end
end
