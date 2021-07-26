# frozen_string_literal: true

module Resolvers
  module InstanceSecurityDashboard
    class ProjectsResolver < BaseResolver
      type ::Types::ProjectType, null: true

      argument :search, GraphQL::Types::String,
               required: false,
               description: 'Search query for project name, path, or description.'

      alias_method :dashboard, :object

      def resolve(**args)
        projects = dashboard&.projects
        args[:search] ? projects&.search(args[:search]) : projects
      end
    end
  end
end
