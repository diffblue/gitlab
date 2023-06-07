# frozen_string_literal: true

module EE
  module Packages
    module Downloadable
      extend ::Gitlab::Utils::Override

      override :touch_last_downloaded_at
      def touch_last_downloaded_at
        super unless ::Gitlab::Geo.secondary?
      end
    end
  end
end
