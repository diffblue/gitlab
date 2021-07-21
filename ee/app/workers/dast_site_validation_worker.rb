# frozen_string_literal: true

class DastSiteValidationWorker
  include ApplicationWorker

  data_consistency :always

  idempotent!

  sidekiq_options retry: 3, dead: false

  sidekiq_retry_in { 25 }

  feature_category :dynamic_application_security_testing
  tags :exclude_from_kubernetes

  sidekiq_retries_exhausted do |job|
    dast_site_validation = DastSiteValidation.find(job['args'][0])
    dast_site_validation.fail_op
  end

  def perform(dast_site_validation_id)
    dast_site_validation = DastSiteValidation.find(dast_site_validation_id)
    project = dast_site_validation.project

    DastSiteValidations::ValidateService.new(
      container: project,
      params: { dast_site_validation: dast_site_validation }
    ).execute!
  end
end
