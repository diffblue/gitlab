# frozen_string_literal: true

module AuditEvents
  module ExternallyDestinationable
    extend ActiveSupport::Concern

    included do
      validates :destination_url, public_url: true, presence: true
      validates :destination_url, uniqueness: true, length: { maximum: 255 }
      validates :verification_token, length: { in: 16..24 }, allow_nil: true
      validates :verification_token, presence: true, on: :update

      has_secure_token :verification_token, length: 24

      def audit_details
        destination_url
      end
    end
  end
end
