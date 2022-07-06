# frozen_string_literal: true

module Mutations
  module SharedEpicArguments
    extend ActiveSupport::Concern

    prepended do
      argument :group_path, GraphQL::Types::ID,
               required: true,
               description: "Group the epic to mutate is in."

      argument :title,
                GraphQL::Types::String,
                required: false,
                description: 'Title of the epic.'

      argument :description,
                GraphQL::Types::String,
                required: false,
                description: 'Description of the epic.'

      argument :confidential,
                GraphQL::Types::Boolean,
                required: false,
                description: 'Indicates if the epic is confidential.'

      argument :start_date_fixed,
                GraphQL::Types::String,
                required: false,
                description: 'Start date of the epic.'

      argument :due_date_fixed,
                GraphQL::Types::String,
                required: false,
                description: 'End date of the epic.'

      argument :start_date_is_fixed,
                GraphQL::Types::Boolean,
                required: false,
                description: 'Indicates start date should be sourced from start_date_fixed field not the issue milestones.'

      argument :due_date_is_fixed,
                GraphQL::Types::Boolean,
                required: false,
                description: 'Indicates end date should be sourced from due_date_fixed field not the issue milestones.'
      argument :add_label_ids,
               [GraphQL::Types::ID],
               required: false,
               description: 'IDs of labels to be added to the epic.'
      argument :remove_label_ids,
               [GraphQL::Types::ID],
               required: false,
               description: 'IDs of labels to be removed from the epic.'

      argument :add_labels,
               [GraphQL::Types::String],
               required: false,
               description: 'Array of labels to be added to the epic.'

      argument :color,
               ::Types::ColorType,
               required: false,
               description: 'Color of the epic. Available only when feature flag `epic_color_highlight` is enabled. This flag is disabled by default, because the feature is experimental and is subject to change without notice.'
    end

    def validate_arguments!(args, group)
      args.delete(:color) unless Feature.enabled?(:epic_color_highlight, group)

      if args.empty?
        raise Gitlab::Graphql::Errors::ArgumentError,
          'The list of epic attributes is empty'
      end
    end
  end
end
