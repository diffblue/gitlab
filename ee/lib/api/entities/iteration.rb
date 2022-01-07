# frozen_string_literal: true

module API
  module Entities
    class Iteration < Grape::Entity
      expose :id, :iid
      expose :sequence
      expose :project_id, if: -> (entity, options) { entity&.project_id }
      expose :group_id, if: -> (entity, options) { entity&.group_id }
      expose :title, :description
      expose :state_enum, as: :state
      expose :created_at, :updated_at
      expose :start_date, :due_date

      expose :web_url do |iteration, _options|
        Gitlab::UrlBuilder.build(iteration)
      end
    end
  end
end
