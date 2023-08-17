# frozen_string_literal: true

module EE
  module API
    module Entities
      module Snippet
        extend ActiveSupport::Concern

        prepended do
          expose :repository_storage,
            if: ->(_, options) {
              Ability.allowed?(options[:current_user], :change_repository_storage)
            } do |snippet|
            snippet.snippet_repository&.shard_name
          end
        end
      end
    end
  end
end
