# frozen_string_literal: true

module EE
  module API
    module Entities
      class ResourceWeightEvent < Grape::Entity
        expose :id, documentation: { type: 'string', example: 142 }
        expose :user, using: ::API::Entities::UserBasic
        expose :created_at, documentation: { type: 'dateTime', example: '2012-05-28T04:42:42-07:00' }
        expose :issue_id, documentation: { type: 'string', example: 253 }
        expose :weight, documentation: { type: 'string', example: 3 }
      end
    end
  end
end
