# frozen_string_literal: true

module EE
  module Profiles
    module NotificationsController
      extend ::Gitlab::Utils::Override

      private

      override :project_associations
      def project_associations
        super.merge(invited_groups: [])
      end
    end
  end
end
