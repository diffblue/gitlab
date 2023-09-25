# frozen_string_literal: true

module Security
  module ScanResultPolicies
    class PolicyViolationComment
      MESSAGE_HEADER = '<!-- policy_violation_comment -->'
      VIOLATED_REPORTS_HEADER_PATTERN = /<!-- violated_reports: ([a-z_,]+)/
      OPTIONAL_APPROVALS_HEADER_PATTERN = /<!-- optional_approvals: ([a-z_,]+)/
      REPORT_TYPES = {
        license_scanning: 'license_scanning',
        scan_finding: 'scan_finding',
        any_merge_request: 'any_merge_request'
      }.freeze
      MESSAGE_REQUIRES_APPROVAL = <<~TEXT.squish
        Security and compliance scanners enforced by your organization have completed and identified that approvals
        are required due to one or more policy violations.
        Review the policy's rules in the MR widget and assign reviewers to proceed.
      TEXT

      MESSAGE_REQUIRES_NO_APPROVAL = <<~TEXT.squish
        Security and compliance scanners enforced by your organization have completed and identified one or more
        policy violations.
        Consider including optional reviewers based on the policy rules in the MR widget.
      TEXT

      attr_reader :reports, :optional_approval_reports, :existing_comment

      def initialize(existing_comment)
        @existing_comment = existing_comment
        @reports = Set.new
        @optional_approval_reports = Set.new

        return unless existing_comment

        parse_reports
      end

      def add_report_type(report_type, requires_approval)
        add_optional_approval_report(report_type) unless requires_approval
        @reports = (reports + [report_type]) & REPORT_TYPES.values
      end

      def add_optional_approval_report(report_type)
        @optional_approval_reports = (optional_approval_reports + [report_type]) & REPORT_TYPES.values
      end

      def remove_report_type(report_type)
        @optional_approval_reports -= [report_type]
        @reports -= [report_type]
      end

      def body
        return if existing_comment.nil? && reports.empty?

        [MESSAGE_HEADER, body_message].join("\n")
      end

      private

      def parse_reports
        parse_report_list(VIOLATED_REPORTS_HEADER_PATTERN) { |report_type| add_report_type(report_type, true) }
        parse_report_list(OPTIONAL_APPROVALS_HEADER_PATTERN) { |report_type| add_optional_approval_report(report_type) }
      end

      def parse_report_list(pattern, &block)
        match = existing_comment.note.match(pattern)
        match[1].split(',').each(&block) if match
      end

      def fixed_note_body
        'Security policy violations have been resolved.'
      end

      def body_message
        return fixed_note_body if reports.empty?

        message = reports == optional_approval_reports ? MESSAGE_REQUIRES_NO_APPROVAL : MESSAGE_REQUIRES_APPROVAL
        <<~MARKDOWN
          <!-- violated_reports: #{reports.join(',')} -->
          #{"<!-- optional_approvals: #{optional_approval_reports.join(',')} -->" if optional_approval_reports.any?}
          | :warning: **Policy violation(s) detected**|
          | ----------------------------------------- |
          | #{message}                                |

          #{format('Learn more about [Security and Compliance policies](%{url}).',
            url: Rails.application.routes.url_helpers.help_page_url('user/application_security/policies/index'))}
        MARKDOWN
      end
    end
  end
end
