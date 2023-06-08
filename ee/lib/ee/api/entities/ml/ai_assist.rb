# frozen_string_literal: true

module EE
  module API
    module Entities
      module Ml
        class AiAssist < Grape::Entity
          expose :user_is_allowed
          expose :third_party_ai_features_enabled
        end
      end
    end
  end
end
