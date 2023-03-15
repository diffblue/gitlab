# frozen_string_literal: true

# rubocop:disable Graphql/AuthorizeTypes
module Types
  module ProductAnalytics
    class StateEnum < BaseEnum
      graphql_name 'ProductAnalyticsState'
      description 'Current state of the product analytics stack.'

      value 'CREATE_INSTANCE', value: 'create_instance', description: 'Stack has not been created yet.'
      value 'LOADING_INSTANCE', value: 'loading_instance', description: 'Stack is currently initializing.'
      value 'WAITING_FOR_EVENTS', value: 'waiting_for_events', description: 'Stack is waiting for events from users.'
      value 'COMPLETE', value: 'complete', description: 'Stack has been initialized and has data.'
    end
  end
end
# rubocop:enable Graphql/AuthorizeTypes
