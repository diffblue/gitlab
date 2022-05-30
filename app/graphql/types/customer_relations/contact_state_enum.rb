# frozen_string_literal: true

module Types
  module CustomerRelations
    class ContactStateEnum < BaseEnum
      graphql_name 'CustomerRelationsContactState'

      value 'active',
            description: "Active customer.",
            value: :active

      value 'inactive',
            description: "Inactive customer.",
            value: :inactive
    end
  end
end
