# frozen_string_literal: true

module Types
  class IterationSortEnum < BaseEnum
    graphql_name 'IterationSort'
    description 'Iteration sort values'

    value 'CADENCE_AND_DUE_DATE_ASC', 'Sort by cadence id in ascending and due date in ascending order.', value: :cadence_and_due_date_asc
    value 'CADENCE_AND_DUE_DATE_DESC', 'Sort by cadence id in ascending and due date in descending order.', value: :cadence_and_due_date_desc
  end
end
