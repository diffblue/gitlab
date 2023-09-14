# frozen_string_literal: true

module Types
  module GitlabSubscriptions
    class UserAddOnAssignmentType < Types::BaseObject
      graphql_name 'UserAddOnAssignment'
      description 'An assignment of an AddOnPurchase to a User.'

      authorize :admin_add_on_purchase

      field :add_on_purchase,
        type: ::Types::GitlabSubscriptions::AddOnPurchaseType,
        null: false,
        description: 'Add-on purchase the user is assigned to.'
    end
  end
end
