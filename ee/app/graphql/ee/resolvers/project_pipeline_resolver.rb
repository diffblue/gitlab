# frozen_string_literal: true

module EE
  module Resolvers
    module ProjectPipelineResolver
      extend ::Gitlab::Utils::Override

      override :preloads
      def preloads
        super.merge(dast_profile: [Dast::ProfileResolver::DAST_PROFILE_PRELOAD])
      end
    end
  end
end
