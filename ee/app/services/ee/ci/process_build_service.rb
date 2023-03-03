# frozen_string_literal: true
module EE
  module Ci
    module ProcessBuildService
      extend ::Gitlab::Utils::Override

      override :process
      def process(processable)
        if processable.persisted_environment.try(:needs_approval?)
          processable.run_after_commit { |processable| processable.deployment&.block! }
          # To populate the deployment job as manually executable (i.e. `Ci::Build#playable?`),
          # we have to set `manual` to `ci_builds.when` as well as `ci_builds.status`.
          processable.when = 'manual'
          return processable.actionize!
        end

        super
      end

      override :enqueue
      def enqueue(processable)
        if processable.persisted_environment.try(:protected_from?, processable.user)
          return processable.drop!(:protected_environment_failure)
        end

        super
      end
    end
  end
end
