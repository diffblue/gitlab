# frozen_string_literal: true

module AuditEvents
  module Streaming
    module StreamableHeader
      extend ActiveSupport::Concern

      included do
        validates :value, presence: true, length: { maximum: 255 }

        def to_hash
          { key => value }
        end
      end
    end
  end
end
