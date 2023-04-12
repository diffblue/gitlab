# frozen_string_literal: true

module EE
  module API
    module Entities
      module MergeTrains
        class Car < Grape::Entity
          expose :id, documentation: { type: 'integer', example: 38 }
          expose :merge_request, using: ::API::Entities::MergeRequestSimple
          expose :user, using: ::API::Entities::UserBasic
          expose :pipeline, using: ::API::Entities::Ci::PipelineBasic
          expose :created_at, documentation: { type: 'dateTime', example: '2015-12-24T15:51:21.880Z' }
          expose :updated_at, documentation: { type: 'dateTime', example: '2015-12-24T17:54:31.198Z' }
          expose :target_branch, documentation: { type: 'string', example: 'develop' }
          expose :status_name, as: :status,
            documentation: {
              type: 'string',
              values: ::MergeTrains::Car.state_machine.states.map(&:name),
              example: 'merging'
            }
          expose :merged_at, documentation: { type: 'dateTime', example: '2015-12-24T17:54:31.198Z' }
          expose :duration,
            documentation: { type: 'integer', desc: 'Time spent in seconds', example: 127 }
        end
      end
    end
  end
end
