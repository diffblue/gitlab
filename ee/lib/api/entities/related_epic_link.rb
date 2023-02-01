# frozen_string_literal: true

module API
  module Entities
    class RelatedEpicLink < Grape::Entity
      expose :id, documentation: { type: "integer", example: 123 }
      expose :source, as: :source_epic, using: ::EE::API::Entities::Epic
      expose :target, as: :target_epic, using: ::EE::API::Entities::Epic
      expose :link_type, documentation: { type: "string", example: "relates_to" }
      expose :created_at, documentation: { type: "dateTime", example: "2022-01-31T15:10:45.080Z" }
      expose :updated_at, documentation: { type: "dateTime", example: "2022-01-31T15:10:45.080Z" }
    end
  end
end
