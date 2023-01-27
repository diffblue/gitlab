# frozen_string_literal: true

module API
  module Entities
    class EpicBoard < Grape::Entity
      expose :id, documentation: { type: 'integer', example: 1 }
      expose :name, documentation: { type: 'string', example: 'Team Board' }
      expose :hide_backlog_list, documentation: { type: 'boolean', example: false }
      expose :hide_closed_list, documentation: { type: 'boolean', example: true }
      expose :group, using: ::API::Entities::BasicGroupDetails
      expose :labels, using: ::API::Entities::LabelBasic, documentation: { is_array: true }
      expose :lists, using: Entities::EpicBoards::List, documentation: { is_array: true }
    end
  end
end
