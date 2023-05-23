# frozen_string_literal: true

module Types
  module Ci
    module Catalog
      class ResourceSortEnum < SortEnum
        graphql_name 'CiCatalogResourceSort'
        description 'Values for sorting catalog resources'

        value 'NAME_ASC', 'Name by ascending order.', value: :name_asc
        value 'NAME_DESC', 'Name by descending order.', value: :name_desc
      end
    end
  end
end
