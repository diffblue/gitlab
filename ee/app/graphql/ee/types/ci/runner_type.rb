# frozen_string_literal: true

module EE
  module Types
    module Ci
      module RunnerType
        extend ActiveSupport::Concern

        RUNNER_UPGRADE_STATUS_TRANSLATIONS = {
          not_processed: nil
        }.freeze

        prepended do
          field :public_projects_minutes_cost_factor, GraphQL::Types::Float,
            null: true,
            description: 'Public projects\' "compute cost factor" associated with the runner (GitLab.com only).'

          field :private_projects_minutes_cost_factor, GraphQL::Types::Float,
            null: true,
            description: 'Private projects\' "compute cost factor" associated with the runner (GitLab.com only).'

          field :upgrade_status, ::Types::Ci::RunnerUpgradeStatusEnum,
            null: true,
            description: 'Availability of upgrades for the runner.',
            alpha: { milestone: '14.10' }

          def upgrade_status
            return unless upgrade_status_available?

            BatchLoader::GraphQL.for(object.id).batch(key: :upgrade_status) do |runner_ids, loader|
              aggregate_status_by_runner_id = upgrade_status_by_runner_id(runner_ids)

              runner_ids.each do |runner_id|
                status = aggregate_status_by_runner_id[runner_id]
                status = RUNNER_UPGRADE_STATUS_TRANSLATIONS.fetch(status, status)

                loader.call(runner_id, status)
              end
            end
          end

          private

          def upgrade_status_available?
            return false unless ::Gitlab::Ci::RunnerReleases.instance.enabled?

            Ability.allowed?(current_user, :read_runner_upgrade_status)
          end

          def upgrade_status_by_runner_id(runner_ids)
            ::Ci::RunnerManager
              .for_runner(runner_ids)
              .aggregate_upgrade_status_by_runner_id
          end
        end
      end
    end
  end
end
