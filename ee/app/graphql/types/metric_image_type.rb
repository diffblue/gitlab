# frozen_string_literal: true

module Types
  class MetricImageType < BaseObject
    graphql_name 'MetricImage'
    description 'Represents a metric image upload'

    authorize :read_issuable_metric_image

    field :id, GraphQL::Types::ID, null: false,
          description: 'ID of the metric upload.'

    field :iid, GraphQL::Types::ID, null: false,
          description: 'Internal ID of the metric upload.'

    field :url, GraphQL::Types::String, null: false,
          description: 'URL of the metric source.'

    field :file_name, GraphQL::Types::String, null: true,
          description: 'File name of the metric image.',
          method: :filename

    field :file_path, GraphQL::Types::String, null: true,
          description: 'File path of the metric image.'
  end
end
