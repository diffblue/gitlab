# frozen_string_literal: true

module Security
  class MergeRequestSecurityReportGenerationService
    include Gitlab::Utils::StrongMemoize

    DEFAULT_FINDING_STATE = 'detected'

    InvalidReportTypeError = Class.new(ArgumentError)

    def self.execute(merge_request, report_type)
      new(merge_request, report_type).execute
    end

    def initialize(merge_request, report_type)
      @merge_request = merge_request
      @report_type = report_type
    end

    def execute
      return report unless report_available?

      set_states_of!(added_findings)
      set_states_of!(fixed_findings)

      report
    end

    private

    attr_reader :merge_request, :report_type

    def report_available?
      report[:status] == :parsed
    end

    def set_states_of!(findings)
      findings.each { |finding| finding['state'] = state_for(finding['uuid']) }
    end

    def state_for(uuid)
      existing_vulnerabilities[uuid] || DEFAULT_FINDING_STATE
    end

    def existing_vulnerabilities
      @existing_vulnerabilities ||= Vulnerability.with_findings_by_uuid(finding_uuids)
                                                 .pluck(:uuid, :state) # rubocop:disable CodeReuse/ActiveRecord
                                                 .to_h
    end

    def finding_uuids
      (added_findings + fixed_findings).pluck('uuid') # rubocop:disable CodeReuse/ActiveRecord
    end

    def added_findings
      @added_findings ||= report.dig(:data, 'added')
    end

    def fixed_findings
      @fixed_findings ||= report.dig(:data, 'fixed')
    end

    strong_memoize_attr def report
      case report_type
      when 'sast'
        merge_request.compare_sast_reports(nil)
      when 'secret_detection'
        merge_request.compare_secret_detection_reports(nil)
      when 'container_scanning'
        merge_request.compare_container_scanning_reports(nil)
      when 'dependency_scanning'
        merge_request.compare_dependency_scanning_reports(nil)
      when 'dast'
        merge_request.compare_dast_reports(nil)
      when 'coverage_fuzzing'
        merge_request.compare_coverage_fuzzing_reports(nil)
      when 'api_fuzzing'
        merge_request.compare_api_fuzzing_reports(nil)
      else
        raise InvalidReportTypeError
      end
    end
  end
end
