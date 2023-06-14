# frozen_string_literal: true

module Security
  module ScanResultPolicies
    class PolicyViolationComment
      MESSAGE_HEADER = '<!-- policy_violation_comment -->'
      VIOLATED_REPORTS_HEADER_PATTERN = /<!-- violated_reports: ([a-z_,]+)/
      REPORT_TYPES = {
        license_scanning: 'license_scanning',
        scan_finding: 'scan_finding'
      }.freeze

      attr_reader :reports, :existing_comment

      def initialize(existing_comment)
        @existing_comment = existing_comment
        @reports = Set.new

        return unless existing_comment

        match = existing_comment.note.match(VIOLATED_REPORTS_HEADER_PATTERN)
        match[1].split(',').each { |report_type| add_report_type(report_type) } if match
      end

      def add_report_type(report_type)
        @reports = (reports + [report_type]) & REPORT_TYPES.values
      end

      def remove_report_type(report_type)
        @reports -= [report_type]
      end

      def body
        return if existing_comment.nil? && reports.empty?

        [MESSAGE_HEADER, body_message].join("\n")
      end

      private

      def fixed_note_body
        'Security policy violations have been resolved.'
      end

      def body_message
        return fixed_note_body if reports.empty?

        message = <<~TEXT.squish
          Security and compliance scanners enforced by your organization have completed and identified that approvals
          are required due to one or more policy violations.
          Review the policy's rules in the MR widget and assign reviewers to proceed.
        TEXT
        <<~MARKDOWN
          <!-- violated_reports: #{reports.join(',')} -->
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
