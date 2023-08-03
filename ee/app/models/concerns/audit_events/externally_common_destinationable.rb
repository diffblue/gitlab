# frozen_string_literal: true

module AuditEvents
  module ExternallyCommonDestinationable
    extend ActiveSupport::Concern

    included do
      before_validation :assign_default_name

      validates :name, length: { maximum: 72 }

      private

      def assign_default_name
        self.name ||= "Destination_#{SecureRandom.uuid}"
      end
    end
  end
end
