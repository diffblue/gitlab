# frozen_string_literal: true

module EE
  module API
    module Entities
      class ProjectAlias < Grape::Entity
        expose :id, documentation: { type: 'integer', example: 1 }
        expose :project_id, documentation: { type: 'integer', example: 1 }
        expose :name, documentation: { type: 'string', example: 'gitlab' }
      end
    end
  end
end
