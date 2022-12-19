# frozen_string_literal: true

module Dast
  class ScannerProfileTag < ApplicationRecord
    self.table_name = 'dast_scanner_profiles_tags'

    belongs_to :tag, class_name: 'ActsAsTaggableOn::Tag', optional: false
    belongs_to :dast_scanner_profile, class_name: 'DastScannerProfile', optional: false
  end
end
