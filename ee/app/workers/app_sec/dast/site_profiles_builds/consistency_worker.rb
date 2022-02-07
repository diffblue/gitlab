# frozen_string_literal: true

module AppSec
  module Dast
    module SiteProfilesBuilds
      class ConsistencyWorker
        include ApplicationWorker

        data_consistency :always

        deduplicate :until_executed
        idempotent!

        feature_category :dynamic_application_security_testing

        def perform(ci_pipeline_id, dast_site_profile_id)
          ::Dast::SiteProfilesBuild.create!(ci_build_id: ci_pipeline_id, dast_site_profile_id: dast_site_profile_id)
        rescue ActiveRecord::RecordNotUnique
          # assume record is already associated
        end
      end
    end
  end
end
