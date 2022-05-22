# frozen_string_literal: true

module AppSec
  module Dast
    module UrlAddressable
      extend ::ActiveSupport::Concern

      included do
        validates :url, addressable_url: true
      end
    end
  end
end
