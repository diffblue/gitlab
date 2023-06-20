# frozen_string_literal: true

module AuditEvents
  module ExternallyDestinationable
    extend ActiveSupport::Concern

    STREAMING_TOKEN_HEADER_KEY = "X-Gitlab-Event-Streaming-Token"
    MAXIMUM_HEADER_COUNT = 20

    included do
      before_validation :assign_default_name

      validates :destination_url, public_url: true, presence: true
      validates :destination_url, uniqueness: true, length: { maximum: 255 }
      validates :verification_token, length: { in: 16..24 }, allow_nil: true
      validates :verification_token, presence: true, on: :update
      validate :no_more_than_20_headers?
      validates :name, length: { maximum: 72 }

      has_secure_token :verification_token, length: 24

      def audit_details
        destination_url
      end

      def headers_hash
        { STREAMING_TOKEN_HEADER_KEY => verification_token }.merge(headers.map(&:to_hash).inject(:merge).to_h)
      end

      private

      def assign_default_name
        self.name ||= "Destination_#{SecureRandom.uuid}"
      end

      def no_more_than_20_headers?
        return unless headers.count > MAXIMUM_HEADER_COUNT

        errors.add(:headers, "are limited to #{MAXIMUM_HEADER_COUNT} per destination")
      end
    end
  end
end
