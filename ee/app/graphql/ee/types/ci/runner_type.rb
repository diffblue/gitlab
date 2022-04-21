# frozen_string_literal: true

module EE
  module Types
    module Ci
      module RunnerType
        extend ActiveSupport::Concern

        prepended do
          field :public_projects_minutes_cost_factor, GraphQL::Types::Float, null: true,
                description: 'Public projects\' "minutes cost factor" associated with the runner (GitLab.com only).'
          field :private_projects_minutes_cost_factor, GraphQL::Types::Float, null: true,
                description: 'Private projects\' "minutes cost factor" associated with the runner (GitLab.com only).'

          field :upgrade_status, ::Types::Ci::RunnerUpgradeStatusTypeEnum, null: true,
                description: 'Availability of upgrades for the runner.',
                deprecated: { milestone: '14.10', reason: :alpha }

          def upgrade_status
            ::Gitlab::Ci::RunnerUpgradeCheck.instance.check_runner_upgrade_status(object.version)
          end
        end
      end
    end
  end
end
