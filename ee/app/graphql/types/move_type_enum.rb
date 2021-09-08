# frozen_string_literal: true

module Types
  class MoveTypeEnum < BaseEnum
    graphql_name 'MoveType'
    description 'The position to which the adjacent object should be moved'

    value 'before', 'Adjacent object is moved before the object that is being moved.'
    value 'after', 'Adjacent object is moved after the object that is being moved.'
  end
end
