# frozen_string_literal: true

module Dast
  class ScannerProfilesBuild < ApplicationRecord
    include AppSec::Dast::Buildable

    self.table_name = 'dast_scanner_profiles_builds'

    belongs_to :ci_build, class_name: 'Ci::Build', optional: false
    belongs_to :dast_scanner_profile, class_name: 'DastScannerProfile', optional: false

    validates :ci_build_id, :dast_scanner_profile_id, presence: true

    alias_attribute :profile, :dast_scanner_profile
  end
end
