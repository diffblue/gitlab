# frozen_string_literal: true

module Autocomplete
  class IterationEntity < Grape::Entity
    expose :id
    expose :display_text, as: :title
    expose :reference, &:to_reference
  end
end
