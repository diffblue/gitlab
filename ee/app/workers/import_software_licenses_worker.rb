# frozen_string_literal: true

class ImportSoftwareLicensesWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  queue_namespace :cronjob
  feature_category :software_composition_analysis

  def perform
    catalogue.each do |spdx_license|
      next if spdx_license.deprecated

      if licenses[spdx_license.name]
        licenses_with(spdx_license.name)
          .update_all(spdx_identifier: spdx_license.id)
      else
        SoftwareLicense.safe_find_or_create_by!(
          name: spdx_license.name,
          spdx_identifier: spdx_license.id
        )
      end
    end

    Rails.cache.delete(SoftwareLicense::ALL_LICENSE_NAMES_CACHE_KEY)
  end

  private

  def licenses
    @licenses ||=
      licenses_with(catalogue.map(&:name)).grouped_by_name.count
  end

  def licenses_with(name)
    SoftwareLicense.by_name(name)
  end

  def catalogue
    @catalogue ||= Gitlab::SPDX::Catalogue.latest
  end
end
