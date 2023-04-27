# frozen_string_literal: true

module Types
  module Ai
    class BaseMethodInputType < BaseInputObject
      argument :resource_id,
        ::Types::GlobalIDType[::Ai::Model],
        required: true,
        description: "Global ID of the resource to mutate."
    end
  end
end
