# frozen_string_literal: true

module EE
  module API
    module Entities
      class SamlGroupLink < Grape::Entity
        expose :saml_group_name, as: :name
        expose :access_level
      end
    end
  end
end
