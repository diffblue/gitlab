# frozen_string_literal: true

module Types
  module Sbom
    class DependencySortEnum < BaseEnum
      graphql_name 'DependencySort'
      description 'Values for sorting dependencies'

      value 'NAME_DESC', 'Name by descending order.', value: :name_desc
      value 'NAME_ASC', 'Name by ascending order.', value: :name_asc
      value 'PACKAGER_DESC', 'Packager by descending order.', value: :packager_desc
      value 'PACKAGER_ASC', 'Packager by ascending order.', value: :packager_asc
    end
  end
end
