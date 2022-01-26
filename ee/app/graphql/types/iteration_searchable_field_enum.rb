# frozen_string_literal: true

module Types
  class IterationSearchableFieldEnum < BaseEnum
    graphql_name 'IterationSearchableField'
    description 'Fields to perform the search in'

    IterationsFinder::SEARCHABLE_FIELDS.each do |field|
      value field.to_s.upcase, value: field, description: "Search in #{field} field."
    end
  end
end
