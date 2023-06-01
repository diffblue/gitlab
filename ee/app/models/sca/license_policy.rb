# frozen_string_literal: true

module SCA
  class LicensePolicy
    CLASSIFICATION_RANKING = { 'allowed' => 0, 'unclassified' => 1, 'denied' => 2 }.freeze
    ATTRIBUTES = {
      classification: ->(policy) { CLASSIFICATION_RANKING[policy.classification] },
      name: ->(policy) { policy.name }
    }.with_indifferent_access

    attr_reader :id, :name, :url, :dependencies, :spdx_identifier, :classification,
      :approval_status

    def initialize(reported_license, software_policy, approval_status = nil)
      @approval_status = approval_status || software_policy&.approval_status || 'unclassified'
      @id = software_policy&.id
      @name = software_policy&.name || reported_license&.name
      @url = reported_license&.url
      @dependencies = reported_license&.dependencies || []
      @spdx_identifier = software_policy&.spdx_identifier || reported_license&.id
      @classification = approval_status || software_policy&.classification || 'unclassified'
    end
  end
end
