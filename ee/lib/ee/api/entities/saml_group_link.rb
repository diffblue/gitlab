# frozen_string_literal: true

module EE
  module API
    module Entities
      class SamlGroupLink < Grape::Entity
        expose :saml_group_name, as: :name, documentation: { type: 'string', example: 'saml-group-1' }
        expose :access_level, documentation: { type: 'integer', example: 40 }
      end
    end
  end
end
