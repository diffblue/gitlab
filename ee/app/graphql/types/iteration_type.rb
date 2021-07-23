# frozen_string_literal: true

module Types
  class IterationType < BaseObject
    graphql_name 'Iteration'
    description 'Represents an iteration object'

    present_using IterationPresenter

    authorize :read_iteration

    implements ::Types::TimeboxReportInterface

    field :id, GraphQL::Types::ID, null: false,
          description: 'ID of the iteration.'

    field :iid, GraphQL::Types::ID, null: false,
          description: 'Internal ID of the iteration.'

    field :title, GraphQL::Types::String, null: false,
          description: 'Title of the iteration.'

    field :description, GraphQL::Types::String, null: true,
          description: 'Description of the iteration.'
    markdown_field :description_html, null: true

    field :state, Types::IterationStateEnum, null: false,
          description: 'State of the iteration.'

    field :web_path, GraphQL::Types::String, null: false, method: :iteration_path,
          description: 'Web path of the iteration.'

    field :web_url, GraphQL::Types::String, null: false, method: :iteration_url,
          description: 'Web URL of the iteration.'

    field :scoped_path, GraphQL::Types::String, null: true, method: :scoped_iteration_path, extras: [:parent],
          description: 'Web path of the iteration, scoped to the query parent. Only valid for Project parents. Returns null in other contexts.'

    field :scoped_url, GraphQL::Types::String, null: true, method: :scoped_iteration_url, extras: [:parent],
          description: 'Web URL of the iteration, scoped to the query parent. Only valid for Project parents. Returns null in other contexts.'

    field :due_date, Types::TimeType, null: true,
          description: 'Timestamp of the iteration due date.'

    field :start_date, Types::TimeType, null: true,
          description: 'Timestamp of the iteration start date.'

    field :created_at, Types::TimeType, null: false,
          description: 'Timestamp of iteration creation.'

    field :updated_at, Types::TimeType, null: false,
          description: 'Timestamp of last iteration update.'

    field :iteration_cadence, Types::Iterations::CadenceType, null: false,
          description: 'Cadence of the iteration.'

    def iteration_cadence
      ::Gitlab::Graphql::Loaders::BatchModelLoader.new(::Iterations::Cadence, object.iterations_cadence_id).find
    end
  end
end
