# frozen_string_literal: true

module Autocomplete
  class GroupEntity < Grape::Entity
    expose :id
    expose :name
    expose :avatar_url
  end
end
