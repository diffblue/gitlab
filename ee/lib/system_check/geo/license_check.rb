# frozen_string_literal: true

module SystemCheck
  module Geo
    class LicenseCheck < SystemCheck::BaseCheck
      set_name 'GitLab Geo is available'

      def check?
        return true unless Gitlab::Geo.enabled?

        Gitlab::Geo.primary? ? Gitlab::Geo.license_allows? : true
      end

      def self.check_pass
        if Gitlab::Geo.primary? && !Gitlab::Geo.enabled?
          return 'License supports Geo, but Geo is not enabled' if Gitlab::Geo.license_allows?

          return 'License does not support Geo, and Geo is not enabled'
        elsif Gitlab::Geo.enabled? && !Gitlab::Geo.license_allows?
          return 'License only required on a primary site'
        end

        ""
      end

      def show_error
        try_fixing_it(
          'Add a new license that includes the GitLab Geo feature'
        )

        for_more_information('https://about.gitlab.com/features/gitlab-geo/')
      end
    end
  end
end
