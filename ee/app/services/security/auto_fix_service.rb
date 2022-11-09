# frozen_string_literal: true

module Security
  class AutoFixService
    def initialize(project, pipeline)
      @project = project
      @pipeline = pipeline
    end

    def execute
      return ServiceResponse.error(message: 'Auto fix is disabled') unless project.security_setting.auto_fix_enabled?

      vulnerabilities = pipeline.vulnerability_findings.by_report_types(auto_fix_enabled_types)
      processed_vuln_ids = []

      vulnerabilities.each do |vulnerability|
        next if vulnerability.merge_request_feedback.try(:merge_request_id)
        next unless vulnerability.remediations

        result = VulnerabilityFeedback::CreateService.new(project, User.security_bot, service_params(vulnerability)).execute

        next unless result[:status] == :success

        assign_label(result[:vulnerability_feedback].merge_request)

        processed_vuln_ids.push vulnerability.id
      end

      if processed_vuln_ids.any?
        ServiceResponse.success
      else
        ServiceResponse.error(message: 'Impossible to create Merge Requests')
      end
    end

    private

    attr_reader :project, :pipeline

    def auto_fix_enabled_types
      project.security_setting.auto_fix_enabled_types
    end

    def assign_label(merge_request)
      ::MergeRequests::UpdateService.new(project: project, current_user: User.security_bot, params: { add_label_ids: [label.id] })
        .execute(merge_request)
    end

    def label
      return @label if @label

      service = ::Security::AutoFixLabelService.new(container: project, current_user: User.security_bot).execute
      @label = service.payload[:label]
    end

    def service_params(vulnerability)
      {
        feedback_type: :merge_request,
        category: vulnerability.report_type,
        project_fingerprint: vulnerability.project_fingerprint,
        finding_uuid: vulnerability.uuid,
        vulnerability_data: {
          severity: vulnerability.severity,
          confidence: vulnerability.confidence,
          description: vulnerability.description,
          solution: vulnerability.solution,
          remediations: vulnerability.remediations,
          category: vulnerability.report_type,
          title: vulnerability.name,
          name: vulnerability.name,
          location: vulnerability.location,
          links: vulnerability.links,
          identifiers: vulnerability.identifiers.map(&:attributes)
        }
      }
    end
  end
end
