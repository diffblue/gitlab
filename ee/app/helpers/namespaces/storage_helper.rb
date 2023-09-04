# frozen_string_literal: true

module Namespaces
  module StorageHelper
    include ActiveSupport::NumberHelper

    def used_storage_percentage(usage_ratio)
      number_to_percentage(usage_ratio * 100, precision: 0)
    end
  end
end
