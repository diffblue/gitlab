# frozen_string_literal: true
module EE
  module Ci
    module ProcessBuildService
      extend ::Gitlab::Utils::Override

      override :process
      def process(build)
        if build.persisted_environment.try(:needs_approval?)
          build.run_after_commit { |build| build.deployment&.block! }
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
