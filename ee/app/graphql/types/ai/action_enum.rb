# frozen_string_literal: true

module Types
  module Ai
    class ActionEnum < BaseEnum
      graphql_name 'AiAction'
      description 'Action to subscribe to.'

      value 'CHAT', description: 'Chat action.', value: 'chat'
    end
  end
end
