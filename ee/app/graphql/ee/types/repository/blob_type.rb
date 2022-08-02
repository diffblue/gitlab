# frozen_string_literal: true
module EE
  module Types
    module Repository
      module BlobType
        extend ActiveSupport::Concern

        prepended do
          field :code_owners, [::Types::UserType],
            null: true,
            description: 'List of code owners for the blob.',
            calls_gitaly: true
        end
      end
    end
  end
end
