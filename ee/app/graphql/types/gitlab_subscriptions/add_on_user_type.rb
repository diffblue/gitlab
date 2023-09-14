# frozen_string_literal: true

module Types
  module GitlabSubscriptions
    class AddOnUserType < UserType
      graphql_name 'AddOnUser'
      description 'A user with add-on data'

      authorize :read_user

      field :add_on_assignments,
        type: ::Types::GitlabSubscriptions::UserAddOnAssignmentType.connection_type,
        resolver: ::Resolvers::GitlabSubscriptions::UserAddOnAssignmentsResolver,
        description: 'Add-on purchase assignments for the user.',
        alpha: { milestone: '16.4' }
    end
  end
end
