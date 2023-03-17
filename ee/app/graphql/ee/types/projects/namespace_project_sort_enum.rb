# frozen_string_literal: true

module EE
  module Types
    module Projects
      module NamespaceProjectSortEnum
        extend ActiveSupport::Concern

        prepended do
          # Storage size
          value 'STORAGE', 'Sort by excess repository storage size, descending order.',
            value: :excess_repo_storage_size_desc

          # project_statistics columns
          value 'STORAGE_SIZE_ASC',  'Sort by total storage size, ascending order.', value: :storage_size_asc
          value 'STORAGE_SIZE_DESC', 'Sort by total storage size, descending order.', value: :storage_size_desc
        end
      end
    end
  end
end
