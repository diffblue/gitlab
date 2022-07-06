# frozen_string_literal: true

module EE
  module Ci
    module Metadatable
      extend ActiveSupport::Concern

      prepended do
        delegate :secrets, to: :metadata, allow_nil: true
      end

      def secrets?
        !!metadata&.secrets?
      end

      def secrets=(value)
        ensure_metadata.secrets = value
      end
    end
  end
end
