# frozen_string_literal: true

module Vulnerabilities
  class StateTransitionEntity < Grape::Entity
    expose :author, using: UserEntity
    expose :comment
    expose :from_state
    expose :to_state
    expose :created_at
    expose :dismissal_reason
  end
end
