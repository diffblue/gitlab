# frozen_string_literal: true

module Vulnerabilities
  module Findings
    class FindOrCreateFromSecurityFindingService < ::BaseProjectService
      include ::VulnerabilityFindingHelpers

      def execute
        return ServiceResponse.error(message: _('Security Finding not found')) unless security_finding

        return ServiceResponse.error(message: _('Report Finding not found')) unless report_finding

        unless vulnerability_finding.persisted?
          return ServiceResponse.error(message: vulnerability_finding_creation_error_msg)
        end

        ServiceResponse.success(payload: { vulnerability_finding: vulnerability_finding })
      end

      private

      def vulnerability_finding_creation_error_msg
        format(_("Error creating vulnerability finding: %{errors}"),
errors: vulnerability_finding.errors.full_messages.join(', '))
      end

      def vulnerability_finding
        vulnerability_finding = Vulnerabilities::Finding.by_uuid(params[:security_finding_uuid])&.first
        return vulnerability_finding if vulnerability_finding.present?

        vulnerability_finding = build_vulnerability_finding(security_finding)

        Vulnerabilities::Finding.transaction do
          save_identifiers(vulnerability_finding.identifiers)

          raise ActiveRecord::Rollback unless vulnerability_finding.save
        end

        vulnerability_finding
      end

      def save_identifiers(identifiers)
        return if identifiers.blank?

        identifiers = identifiers.each do |identifier|
          identifier.created_at = identifier.updated_at = Time.zone.now
        end

        identifier_ids = Vulnerabilities::Identifier.bulk_upsert!(
          identifiers,
          unique_by: %i[project_id fingerprint],
          returns: :id
        )

        identifier_ids.each_with_index do |id, index|
          identifiers[index].id = id
          # We need to mark the identifiers as persisted, otherwise ActiveRecord
          # will try to insert identifiers again while saving the finding object
          identifiers[index].instance_variable_set(:@new_record, false)
        end
      end

      def security_finding
        @security_finding ||= Security::Finding
          .with_pipeline_entities
          .latest_by_uuid(params[:security_finding_uuid])
      end

      def report_finding
        @report_finding ||= report_finding_for(security_finding)
      end

      def report_finding_for(security_finding)
        reports = security_finding.build.job_artifacts.map(&:security_report).compact
        return unless reports.present?

        lookup_uuid = security_finding.overridden_uuid || security_finding.uuid

        reports.flat_map(&:findings).find { |finding| finding.uuid == lookup_uuid }
      end

      def pipeline
        security_finding.build.pipeline
      end

      def vulnerability_for(security_finding_uuid)
        project.vulnerabilities.with_findings_by_uuid(security_finding_uuid)&.first
      end
    end
  end
end
