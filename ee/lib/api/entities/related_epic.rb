# frozen_string_literal: true

module API
  module Entities
    class RelatedEpic < EE::API::Entities::Epic
      expose :related_epic_link_id
      expose :epic_link_type, as: :link_type
      expose :related_epic_link_created_at, as: :link_created_at
      expose :related_epic_link_updated_at, as: :link_updated_at
    end
  end
end
