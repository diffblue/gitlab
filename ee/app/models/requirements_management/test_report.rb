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

    class << self
      # Until old requirement iids are deprecated in favor of work items
      # we keep parsing two kinds of reports to toggle requirements status:
      #
      # 1. When 'legacy' parameter is true we search for requirements using iids
      # 2. When 'legacy' parameter is false we search for requirements using work-items iids
      #
      # The first option will be deprecated soon, more information at https://gitlab.com/groups/gitlab-org/-/epics/9203
      def persist_requirement_reports(build, ci_report, legacy: false)
        timestamp = Time.current

        reports = if ci_report.all_passed?
                    passed_reports_for_all_requirements(build, timestamp)
                  else
                    individual_reports(build, ci_report, timestamp, legacy)
                  end

        bulk_insert!(reports)
      end

      def build_report(state:, requirement_issue:, author: nil, build: nil, timestamp: Time.current, legacy: false)
        new(
          issue_id: requirement_issue.id,
          build_id: build&.id,
          author_id: build&.user_id || author&.id,
          created_at: timestamp,
          state: state,
          uses_legacy_iid: !!legacy
        )
      end

      private

      def passed_reports_for_all_requirements(build, timestamp)
        [].tap do |reports|
          build.project.issues.with_issue_type(:requirement).opened.select(:id).find_each do |requirement_issue|
            reports << build_report(state: :passed, requirement_issue: requirement_issue, build: build, timestamp: timestamp)
          end
        end
      end

      def individual_reports(build, ci_report, timestamp, legacy)
        [].tap do |reports|
          iids = ci_report.requirements.keys
          break [] if iids.empty?

          find_requirement_issues_by(iids, build, legacy).each do |requirement_issue|
            # ignore anything with any unexpected state
            new_state =
              if legacy
                ci_report.requirements[requirement_issue.requirement_iid.to_s]
              else
                ci_report.requirements[requirement_issue.work_item_iid.to_s]
              end

            next unless states.key?(new_state)

            reports << build_report(state: new_state, requirement_issue: requirement_issue, build: build, timestamp: timestamp, legacy: legacy)
          end
        end
      end

      def find_requirement_issues_by(iids, build, legacy)
        # Requirement objects are used as proxy to use same iids from before.
        # It makes API endpoints and pipelines references still compatible with old and new requirements iids.
        # For more information check: https://gitlab.com/gitlab-org/gitlab/-/issues/345842#note_810067092
        if legacy
          build.project.issues.opened.for_requirement_iids(iids)
            .select('issues.id, requirement.iid as requirement_iid')
        else
          build.project.issues.opened.with_issue_type(:requirement).where(iid: iids)
            .select('issues.id, issues.iid as work_item_iid')
        end
      end
    end

    def only_requirement_type_issue
      return unless requirement_issue && !requirement_issue.work_item_type.requirement? && will_save_change_to_issue_id?

      errors.add(
        :requirement_issue,
        "must be a `requirement`. You cannot associate a Test Report with a #{requirement_issue.work_item_type.base_type}."
      )
    end
  end
end
