# frozen_string_literal: true

module GroupIssuableResolver
  extend ActiveSupport::Concern

  included do
    argument :include_subgroups, GraphQL::Types::Boolean,
              required: false,
              default_value: false,
              description: "Include #{issuable_collection_name} belonging to subgroups"

    argument :non_archived, GraphQL::Types::Boolean,
              required: false,
              default_value: true,
              description: "Return #{issuable_collection_name} from non archived projects"
  end

  def resolve(**args)
    args[:non_archived] = !args.delete(:include_archived)

    super
  end
end
