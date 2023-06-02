# frozen_string_literal: true

module EE
  module Types
    module Ci
      module RunnerManagerType
        extend ActiveSupport::Concern

        RUNNER_UPGRADE_STATUS_TRANSLATIONS = {
          error: nil
        }.freeze

        prepended do
          field :upgrade_status, ::Types::Ci::RunnerUpgradeStatusEnum,
            null: true,
            description: 'Availability of upgrades for the runner manager.',
            alpha: { milestone: '16.1' }

          def upgrade_status
            return unless upgrade_status_available?

            _, status = ::Gitlab::Ci::RunnerUpgradeCheck.new(::Gitlab::VERSION)
              .check_runner_upgrade_suggestion(runner_manager.version)
            RUNNER_UPGRADE_STATUS_TRANSLATIONS.fetch(status, status)
          end

          private

          def upgrade_status_available?
            return false unless ::Gitlab::Ci::RunnerReleases.instance.enabled?

            Ability.allowed?(current_user, :read_runner_upgrade_status)
          end
        end
      end
    end
  end
end
