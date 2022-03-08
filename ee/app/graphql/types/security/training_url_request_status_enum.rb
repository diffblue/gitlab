# frozen_string_literal: true

module Types
  module Security
    class TrainingUrlRequestStatusEnum < BaseEnum
      graphql_name 'TrainingUrlRequestStatus'
      description 'Status of the request to the training provider. The URL of a TrainingUrl is calculated asynchronously. When PENDING, the URL of the TrainingUrl will be null. When COMPLETED, the URL of the TrainingUrl will be available.'

      value 'PENDING', value: 'pending', description: 'Pending request.'
      value 'COMPLETED', value: 'completed', description: 'Completed request.'
    end
  end
end
