# frozen_string_literal: true

module EE
  module Mutations
    module Ci
      module Runner
        module Update
          extend ActiveSupport::Concern
          extend ::Gitlab::Utils::Override

          prepended do
            argument :public_projects_minutes_cost_factor, GraphQL::Types::Float,
                     required: false,
                     description: 'Public projects\' "minutes cost factor" associated with the runner (GitLab.com only).'

            argument :private_projects_minutes_cost_factor, GraphQL::Types::Float,
                     required: false,
                     description: 'Private projects\' "minutes cost factor" associated with the runner (GitLab.com only).'
          end
        end
      end
    end
  end
end
