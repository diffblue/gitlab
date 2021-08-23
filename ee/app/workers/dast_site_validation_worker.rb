# frozen_string_literal: true

class DastSiteValidationWorker
  include ApplicationWorker

  data_consistency :always

  idempotent!

  sidekiq_options retry: 3, dead: false

  sidekiq_retry_in { 25 }

  feature_category :dynamic_application_security_testing
  tags :exclude_from_kubernetes

  def perform(_dast_site_validation_id)
    # Scheduled for removal in %15.0
    # Please see https://gitlab.com/gitlab-org/gitlab/-/issues/339088
  end
end
