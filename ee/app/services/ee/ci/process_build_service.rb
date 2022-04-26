# frozen_string_literal: true
module EE
  module Ci
    module ProcessBuildService
      extend ::Gitlab::Utils::Override

      override :process
      def process(build)
        if build.persisted_environment.try(:needs_approval?)
          build.run_after_commit { |build| build.deployment&.block! }
          # To populate the deployment job as manually executable (i.e. `Ci::Build#playable?`),
          # we have to set `manual` to `ci_builds.when` as well as `ci_builds.status`.
          build.when = 'manual'
          return build.actionize!
        end

        super
      end

      override :enqueue
      def enqueue(build)
        if build.persisted_environment.try(:protected_from?, build.user)
          return build.drop!(:protected_environment_failure)
        end

        super
      end
    end
  end
end
