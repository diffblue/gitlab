# frozen_string_literal: true

class RefreshLicenseComplianceChecksWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :software_composition_analysis
  weight 2

  def perform(project_id); end
end
