# frozen_string_literal: true

module API
  module Entities
    class ExternalStatusCheck < Grape::Entity
      expose :id, documentation: { type: 'integer', example: 1 }
      expose :name, documentation: { type: 'string', example: 'QA' }
      expose :project_id, documentation: { type: 'integer', example: 1 }
      expose :external_url, documentation: { type: 'string', example: 'https://www.example.com' }
      expose :protected_branches, using: ::API::Entities::ProtectedBranch, documentation: { is_array: true }
    end
  end
end
