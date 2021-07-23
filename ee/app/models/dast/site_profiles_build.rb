# frozen_string_literal: true

module Dast
  class SiteProfilesBuild < ApplicationRecord
    include AppSec::Dast::Buildable

    self.table_name = 'dast_site_profiles_builds'

    belongs_to :ci_build, class_name: 'Ci::Build', optional: false
    belongs_to :dast_site_profile, class_name: 'DastSiteProfile', optional: false

    validates :ci_build_id, :dast_site_profile_id, presence: true

    alias_attribute :profile, :dast_site_profile
  end
end
