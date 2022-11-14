# frozen_string_literal: true

module API
  module Entities
    class RelatedEpicLink < Grape::Entity
      expose :source, as: :source_epic, using: ::EE::API::Entities::Epic
      expose :target, as: :target_epic, using: ::EE::API::Entities::Epic
      expose :link_type, documentation: { type: "string", example: "relates_to" }
    end
  end
end
