# frozen_string_literal: true

module SCA
  class LicenseCompliance
    include ::Gitlab::Utils::StrongMemoize

    SORT_DIRECTION = {
      asc: -> (items) { items },
      desc: -> (items) { items.reverse }
    }.with_indifferent_access

    def initialize(project, pipeline)
      @project = project
      @pipeline = pipeline
      @scanner = ::Gitlab::LicenseScanning.scanner_for_pipeline(pipeline)
    end

    def policies
      strong_memoize(:policies) do
        unclassified_policies.merge(known_policies).sort.map(&:last)
      end
    end

    def find_policies(detected_only: false, classification: [], sort: { by: :name, direction: :asc })
      record_onboarding_progress

      classifications = Array(classification || [])
      matching_policies = policies.reject do |policy|
        (detected_only && policy.dependencies.none?) ||
          (classifications.present? && !policy.classification.in?(classifications))
      end
      sort_items(items: matching_policies, by: sort&.dig(:by), direction: sort&.dig(:direction))
    end

    def latest_build_for_default_branch
      return if pipeline.blank?

      strong_memoize(:latest_build_for_default_branch) do
        pipeline.builds.latest.license_scan.last
      end
    end

    def report_for(policy)
      build_policy(reported_license_by_license_model(policy.software_license), policy)
    end

    def diff_with(other)
      license_scanning_report
        .diff_with(other.license_scanning_report)
        .transform_values do |reported_licenses|
          reported_licenses.map do |reported_license|
            matching_license_policy =
              known_policies[reported_license.id] ||
              known_policies[reported_license&.name&.downcase]
            build_policy(reported_license, matching_license_policy)
          end
        end
    end

    def license_scanning_report
      strong_memoize(:license_scanning_report) do
        scanner.report
      end
    end

    private

    attr_reader :project, :pipeline, :scanner

    def known_policies
      return {} if project.blank?

      strong_memoize(:known_policies) do
        project.software_license_policies.including_license.unreachable_limit.to_h do |policy|
          [policy.software_license.canonical_id, report_for(policy)]
        end
      end
    end

    # When the license found in the report doesn't match any license
    # of the SPDX License List, we need to find it by name explicitly.
    def reported_license_by_license_model(software_license)
      license_scanning_report[software_license.canonical_id] ||
        license_scanning_report.by_license_name(software_license.name&.downcase)
    end

    def unclassified_policies
      license_scanning_report.licenses.map do |reported_license|
        next if known_policies[reported_license.id] || known_policies[reported_license&.name&.downcase]

        [reported_license.canonical_id, build_policy(reported_license, nil)]
      end.compact.to_h
    end

    def build_policy(reported_license, software_license_policy)
      ::SCA::LicensePolicy.new(reported_license, software_license_policy)
    end

    def sort_items(items:, by:, direction:, available_attributes: ::SCA::LicensePolicy::ATTRIBUTES)
      attribute = available_attributes[by] || available_attributes[:name]
      direction = SORT_DIRECTION[direction] || SORT_DIRECTION[:asc]
      direction.call(items.sort_by { |item| attribute.call(item) })
    end

    def record_onboarding_progress
      return unless pipeline

      Onboarding::Progress.register(pipeline.project.root_namespace, :license_scanning_run)
    end
  end
end
