# frozen_string_literal: true

module EE
  module Types
    module BranchProtections
      module BaseAccessLevelType
        extend ActiveSupport::Concern

        prepended do
          field :user,
                ::Types::AccessLevels::UserType,
                null: true,
                description: 'User associated with this access level.'

          field :group,
                ::Types::AccessLevels::GroupType,
                null: true,
                description: 'Group associated with this access level.'
        end
      end
    end
  end
end
