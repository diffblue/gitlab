# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength, Metrics/BlockLength, Layout/LineLength, Gitlab/RailsLogger
module EE
  module Gitlab
    module BackgroundMigration
      module MigrateVulnerabilitiesFeedbackToVulnerabilitiesStateTransition
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        prepended do
          feedback_type_dismissal = 0

          scope_to ->(relation) {
            relation.where(feedback_type: feedback_type_dismissal, migrated_to_state_transition: false)
          }
          operation_name :migrate_feedback_to_state_transition
        end

        VULNERABILITY_STATES = {
          detected: 1,
          confirmed: 4,
          resolved: 3,
          dismissed: 2
        }.with_indifferent_access.freeze

        MAX_COMMENT_LENGTH = 50_000

        class User < ::ApplicationRecord
          has_many :vulnerability_feedback, foreign_key: :author_id, class_name: 'Feedback'
        end

        class Project < ::ApplicationRecord
          has_many :vulnerability_feedback, class_name: 'Feedback'
        end

        class Vulnerability < ::ApplicationRecord
          self.table_name = "vulnerabilities"

          enum state: VULNERABILITY_STATES
        end

        class Finding < ::ApplicationRecord
          include ShaAttribute

          validates :details, json_schema: { filename: "vulnerability_finding_details" }, if: false

          sha_attribute :project_fingerprint
          sha_attribute :location_fingerprint

          self.table_name = "vulnerability_occurrences"

          belongs_to :vulnerability, class_name: 'Vulnerability'
          has_many :feedbacks, class_name: 'Feedback', inverse_of: :finding, primary_key: 'uuid',
                               foreign_key: 'finding_uuid'
        end

        class SecurityFinding < ::ApplicationRecord
          include PartitionedTable

          self.table_name = 'security_findings'
          self.primary_key = :id
          self.ignored_columns = [:partition_number]

          partitioned_by :partition_number,
                         strategy: :sliding_list,
                         next_partition_if: ->(_) { false },
                         detach_partition_if: ->(_) { false }

          has_many :feedbacks,
                   class_name: 'Feedback',
                   inverse_of: :security_finding,
                   primary_key: 'uuid',
                   foreign_key: 'finding_uuid'

          validates :finding_data, json_schema: { filename: "filename" }, if: false
        end

        class Feedback < ::ApplicationRecord
          include EachBatch
          self.table_name = "vulnerability_feedback"

          belongs_to :project, class_name: 'Project'
          belongs_to :author, class_name: 'User'
          belongs_to :finding,
                     primary_key: :uuid,
                     foreign_key: :finding_uuid,
                     class_name: 'Finding',
                     inverse_of: :feedbacks

          belongs_to :security_finding,
                     primary_key: :uuid,
                     foreign_key: :finding_uuid,
                     class_name: 'SecurityFinding',
                     inverse_of: :feedbacks

          def self.match_on_finding_uuid_or_security_finding_or_project_fingerprint
            where('EXISTS (SELECT 1 FROM vulnerability_occurrences WHERE vulnerability_occurrences.uuid =
                vulnerability_feedback.finding_uuid::varchar)')
              .or(where('EXISTS (SELECT 1 FROM vulnerability_occurrences WHERE
              vulnerability_occurrences.project_fingerprint = vulnerability_feedback.project_fingerprint::bytea)'))
              .or(where('EXISTS (SELECT 1 FROM security_findings WHERE security_findings.uuid =
              vulnerability_feedback.finding_uuid)'))
          end
        end

        class StateTransition < ::ApplicationRecord
          self.table_name = "vulnerability_state_transitions"
        end

        override :perform

        def perform
          each_sub_batch do |batch|
            feedbacks = Feedback.where(id: batch.pluck(:id))

            with_vulnerabilities_finding = feedbacks
                .match_on_finding_uuid_or_security_finding_or_project_fingerprint
                .preload(:security_finding, finding: [:vulnerability])
                .select { |feedback| !feedback.finding.nil? }

            without_vulnerability, with_vulnerability = with_vulnerabilities_finding.partition do |feedback|
              feedback.finding.vulnerability_id.nil?
            end

            security_finding_only = feedbacks.select { |feedback| !feedback.security_finding.nil? && feedback.finding.nil? }

            handle_vulnerability_present_scenario(with_vulnerability)
            handle_vulnerability_finding_present_scenario(without_vulnerability)
            handle_security_findings_only_scenario(security_finding_only)
          end
        end

        private

        def handle_vulnerability_present_scenario(feedbacks)
          feedbacks.each do |feedback|
            ::ApplicationRecord.transaction do
              finding = feedback.finding.lock!("FOR SHARE")

              save_state_transition(
                feedback: feedback,
                vulnerability: finding.vulnerability
              )
            end
          end
        end

        def handle_vulnerability_finding_present_scenario(feedbacks)
          feedbacks.each do |feedback|
            ::ApplicationRecord.transaction do
              finding = feedback.finding.lock!("FOR SHARE")

              project = ::Project.find(feedback.project_id)
              author = ::User.find(feedback.author_id)

              # https://docs.gitlab.com/ee/development/database/batched_background_migrations.html#isolation
              # forbids using application code in background migrations but we have an exception for this
              # in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97699#note_1102465241
              vulnerability = ::Vulnerabilities::CreateService.new(
                project,
                author,
                finding_id: finding.id,
                state: 'dismissed',
                skip_permission_check: true
              ).execute

              if vulnerability.errors.any?
                log_error(
                  message: "Failed to create Vulnerability",
                  errors: vulnerability.errors.full_messages.join("; "),
                  vulnerability_finding_id: finding.id
                )
                raise ActiveRecord::Rollback
              end

              save_state_transition(
                feedback: feedback,
                vulnerability: vulnerability
              )
            end
          end
        end

        def handle_security_findings_only_scenario(feedbacks)
          feedbacks.each do |feedback|
            ::ApplicationRecord.transaction do
              params = {
                security_finding_uuid: feedback.security_finding.uuid
              }

              project = ::Project.find(feedback.project_id)
              author = ::User.find(feedback.author_id)

              # https://docs.gitlab.com/ee/development/database/batched_background_migrations.html#isolation
              # forbids using application code in background migrations but we have an exception for this
              # in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97699#note_1102465241
              response = ::Vulnerabilities::FindOrCreateFromSecurityFindingService.new(
                project: project,
                current_user: author,
                params: params,
                state: 'dismissed',
                skip_permission_check: true
              ).execute

              if response.error?
                log_error(
                  message: "Failed to create Vulnerability from Security::Finding",
                  error: response.message,
                  vulnerability_feedback_id: feedback.id,
                  security_finding_uuid: params[:security_finding_uuid]
                )
                raise ActiveRecord::Rollback
              end

              vulnerability = response.payload[:vulnerability]

              save_state_transition(
                feedback: feedback,
                vulnerability: vulnerability
              )
            end
          end
        end

        def save_state_transition(feedback:, vulnerability:)
          state_transition = build_state_transition(
            feedback: feedback,
            vulnerability: vulnerability
          )

          if state_transition.valid?
            state_transition.save!
            feedback.update!(migrated_to_state_transition: true)
          else
            log_error(
              message: "Failed to create a StateTransition",
              errors: state_transition.errors.full_messages.join(", "),
              feedback_id: feedback.id,
              vulnerability_id: feedback.finding.vulnerability_id
            )
          end
        end

        def build_state_transition(feedback:, vulnerability:)
          from_state = Vulnerability.states[:detected]
          to_state = Vulnerability.states[:dismissed]

          max_length_comment = strip_or_truncate_comment(feedback: feedback)

          attrs = {
            from_state: from_state,
            to_state: to_state,
            comment: max_length_comment,
            dismissal_reason: feedback.dismissal_reason,
            vulnerability_id: vulnerability.id,
            author_id: feedback.author_id,
            created_at: feedback.created_at,
            updated_at: feedback.updated_at
          }

          StateTransition.new(attrs)
        end

        def strip_or_truncate_comment(feedback:)
          strip_all_html_tags(feedback.comment)
            .then { |comment| comment&.truncate(MAX_COMMENT_LENGTH) }
        end

        def strip_all_html_tags(comment)
          sanitizer.sanitize(comment)
        end

        def sanitizer
          @sanitizer ||= Rails::Html::FullSanitizer.new
        end

        def log_error(message:, **rest)
          ::Gitlab::BackgroundMigration::Logger.error(
            class: "MigrateVulnerabilitiesFeedbackToVulnerabilitiesStateTransition",
            message: message,
            **rest
          )
        end
      end
    end
  end
end
# rubocop:enable Metrics/MethodLength, Metrics/BlockLength, Layout/LineLength, Gitlab/RailsLogger
