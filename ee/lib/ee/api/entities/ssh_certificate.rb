# frozen_string_literal: true

module EE
  module API
    module Entities
      class SshCertificate < Grape::Entity
        expose :id, documentation: { type: 'integer', example: 142 }
        expose :title, documentation: { type: 'string', example: 'new ssh cert' }
        expose :key, documentation: { type: 'string' }
        expose :created_at, documentation: { type: "dateTime", example: "2022-01-31T15:10:45.080Z" }
      end
    end
  end
end
