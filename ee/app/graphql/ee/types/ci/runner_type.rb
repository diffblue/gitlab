# frozen_string_literal: true

module EE
  module Types
    module Ci
      module RunnerType
        extend ActiveSupport::Concern

        RUNNER_UPGRADE_STATUS_TRANSLATIONS = {
          error: :unknown
        }.freeze

        prepended do
          field :public_projects_minutes_cost_factor, GraphQL::Types::Float, null: true,
                description: 'Public projects\' "minutes cost factor" associated with the runner (GitLab.com only).'
          field :private_projects_minutes_cost_factor, GraphQL::Types::Float, null: true,
                description: 'Private projects\' "minutes cost factor" associated with the runner (GitLab.com only).'

          field :upgrade_status, ::Types::Ci::RunnerUpgradeStatusTypeEnum, null: true,
                description: 'Availability of upgrades for the runner.',
                deprecated: { milestone: '14.10', reason: :alpha }

          def upgrade_status
            return :unknown unless upgrade_status_available?

            _, status = ::Gitlab::Ci::RunnerUpgradeCheck.instance.check_runner_upgrade_suggestion(runner.version)
            RUNNER_UPGRADE_STATUS_TRANSLATIONS.fetch(status, status)
          end

          private

          def upgrade_status_available?
            License.feature_available?(:runner_upgrade_management) || current_user&.has_paid_namespace?
          end

          def preload_projects_namespaces(projects)
            ActiveRecord::Associations::Preloader.new.preload(projects, :namespace) # rubocop:disable CodeReuse/ActiveRecord
          end
        end
      end
    end
  end
end
