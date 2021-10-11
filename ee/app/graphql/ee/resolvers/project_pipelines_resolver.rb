# frozen_string_literal: true

module EE
  module Resolvers
    module ProjectPipelinesResolver
      extend ::Gitlab::Utils::Override

      override :preloads

      def preloads
        super.merge(dast_profile: [{ dast_profile: [{ dast_site_profile: [:dast_site, :secret_variables] },
                                                    :dast_scanner_profile, :dast_profile_schedule] }])
      end
    end
  end
end
