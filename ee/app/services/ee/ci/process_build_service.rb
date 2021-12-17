# frozen_string_literal: true
module EE
  module Ci
    module ProcessBuildService
      extend ::Gitlab::Utils::Override

      override :enqueue
      def enqueue(build)
        # TODO: Refactor to check these conditions before actionizing or scheduling a build. See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75710#note_756445822
        if build.persisted_environment.try(:protected_from?, build.user)
          return build.drop!(:protected_environment_failure)
        elsif build.persisted_environment.try(:needs_approval?)
          build.actionize!
          return build.deployment&.block!
        end

        super
      end
    end
  end
end
