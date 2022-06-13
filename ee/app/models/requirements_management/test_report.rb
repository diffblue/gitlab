# frozen_string_literal: true

module RequirementsManagement
  class TestReport < ApplicationRecord
    include Sortable
    include BulkInsertSafe

    belongs_to :author, inverse_of: :test_reports, class_name: 'User'
    belongs_to :build, class_name: 'Ci::Build'
    belongs_to :requirement_issue, class_name: 'Issue', foreign_key: :issue_id

    validates :state, presence: true
    validates :requirement_issue, presence: true
    validate :only_requirement_type_issue

    enum state: { passed: 1, failed: 2 }

    scope :without_build, -> { where(build_id: nil) }
    scope :with_build, -> { where.not(build_id: nil) }
    scope :for_user_build, ->(user_id, build_id) { where(author_id: user_id, build_id: build_id) }

    # We need this only to perform permission checks on policy
    delegate :requirement, to: :requirement_issue, allow_nil: true

    class << self
      def persist_requirement_reports(build, ci_report)
        timestamp = Time.current

        reports = if ci_report.all_passed?
                    passed_reports_for_all_requirements(build, timestamp)
                  else
                    individual_reports(build, ci_report, timestamp)
                  end

        bulk_insert!(reports)
      end

      def build_report(author: nil, state:, requirement_issue:, build: nil, timestamp: Time.current)
        new(
          issue_id: requirement_issue.id,
          build_id: build&.id,
          author_id: build&.user_id || author&.id,
          created_at: timestamp,
          state: state
        )
      end

      private

      def passed_reports_for_all_requirements(build, timestamp)
        [].tap do |reports|
          build.project.issues.requirement.opened.select(:id).find_each do |requirement_issue|
            reports << build_report(state: :passed, requirement_issue: requirement_issue, build: build, timestamp: timestamp)
          end
        end
      end

      def individual_reports(build, ci_report, timestamp)
        [].tap do |reports|
          iids = ci_report.requirements.keys
          break [] if iids.empty?

          find_requirement_issues_by(iids, build).each do |requirement_issue|
            # ignore anything with any unexpected state
            new_state = ci_report.requirements[requirement_issue.requirement_iid.to_s]
            next unless states.key?(new_state)

            reports << build_report(state: new_state, requirement_issue: requirement_issue, build: build, timestamp: timestamp)
          end
        end
      end

      def find_requirement_issues_by(iids, build)
        # Requirement objects are used as proxy to use same iids from before.
        # It makes API endpoints and pipelines references still compatible with old and new requirements iids.
        # For more information check: https://gitlab.com/gitlab-org/gitlab/-/issues/345842#note_810067092
        requirement_issues = build.project.issues.opened.for_requirement_iids(iids)

        requirement_issues.select('issues.id, requirement.iid as requirement_iid')
      end
    end

    def only_requirement_type_issue
      errors.add(:requirement_issue, "must be a `requirement`. You cannot associate a Test Report with a #{requirement_issue.issue_type}.") if requirement_issue && !requirement_issue.requirement? && will_save_change_to_issue_id?
    end
  end
end
