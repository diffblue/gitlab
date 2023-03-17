# frozen_string_literal: true

module EE
  module Types
    module Ci
      module RunnerType
        extend ActiveSupport::Concern

        RUNNER_UPGRADE_STATUS_TRANSLATIONS = {
          error: nil
        }.freeze

        prepended do
          field :public_projects_minutes_cost_factor, GraphQL::Types::Float,
            null: true,
            description: 'Public projects\' "minutes cost factor" associated with the runner (GitLab.com only).'

          field :private_projects_minutes_cost_factor, GraphQL::Types::Float,
            null: true,
            description: 'Private projects\' "minutes cost factor" associated with the runner (GitLab.com only).'

          field :upgrade_status, ::Types::Ci::RunnerUpgradeStatusEnum,
            null: true,
            description: 'Availability of upgrades for the runner.',
            alpha: { milestone: '14.10' }

          def upgrade_status
            return unless upgrade_status_available?

            _, status = ::Gitlab::Ci::RunnerUpgradeCheck.new(::Gitlab::VERSION)
              .check_runner_upgrade_suggestion(runner.version)
            RUNNER_UPGRADE_STATUS_TRANSLATIONS.fetch(status, status)
          end

          private

          def upgrade_status_available?
            return false unless ::Gitlab::Ci::RunnerReleases.instance.enabled?

            License.feature_available?(:runner_upgrade_management) || current_user&.has_paid_namespace?
          end
        end
      end
    end
  end
end
