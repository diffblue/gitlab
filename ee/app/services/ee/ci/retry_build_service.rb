# frozen_string_literal: true

module EE
  module Ci
    module RetryBuildService
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      class_methods do
        extend ::Gitlab::Utils::Override

        override :clone_accessors
        def clone_accessors
          (super + extra_accessors).freeze
        end

        override :extra_accessors
        def extra_accessors
          return %i[secrets].freeze if ::Feature.enabled?(:dast_sharded_cloned_ci_builds, default_enabled: :yaml)

          %i[dast_site_profile dast_scanner_profile secrets].freeze
        end
      end

      private

      override :clone_build
      def clone_build(build)
        super do |new_build|
          if ::Feature.enabled?(:dast_sharded_cloned_ci_builds, default_enabled: :yaml)
            new_build.run_after_commit do
              response = AppSec::Dast::Builds::AssociateService.new(
                ci_build_id: new_build.id,
                dast_site_profile_id: build.dast_site_profile&.id,
                dast_scanner_profile_id: build.dast_scanner_profile&.id
              ).execute

              new_build.reset.drop! if response.error?
            end
          end
        end
      end

      override :check_access!
      def check_access!(build)
        super

        if current_user && !current_user.has_required_credit_card_to_run_pipelines?(project)
          ::Gitlab::AppLogger.info(
            message: 'Credit card required to be on file in order to retry build',
            project_path: project.full_path,
            user_id: current_user.id,
            plan: project.root_namespace.actual_plan_name
          )

          raise ::Gitlab::Access::AccessDeniedError, 'Credit card required to be on file in order to retry a build'
        end
      end

      override :check_assignable_runners!
      def check_assignable_runners!(build)
        runner_minutes = ::Gitlab::Ci::Minutes::RunnersAvailability.new(project)
        return if runner_minutes.available?(build.build_matcher)

        build.drop!(:ci_quota_exceeded)
      end
    end
  end
end
