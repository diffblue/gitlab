# frozen_string_literal: true

module EE
  module MergeRequest
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    include ::Gitlab::Allowable
    include ::Gitlab::Utils::StrongMemoize
    include FromUnion

    USES_MERGE_BASE_PIPELINE_FOR_COMPARISON = {
      ::Ci::CompareMetricsReportsService => ->(_project) { true },
      ::Ci::CompareCodequalityReportsService => ->(_project) { true },
      ::Ci::CompareSecurityReportsService => ->(_project) { true }
    }.freeze

    prepended do
      include Elastic::ApplicationVersionedSearch
      include DeprecatedApprovalsBeforeMerge
      include UsageStatistics
      include IterationEventable

      belongs_to :iteration, foreign_key: 'sprint_id'

      has_many :approvers, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
      has_many :approver_users, through: :approvers, source: :user
      has_many :approver_groups, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
      has_many :status_check_responses, class_name: 'MergeRequests::StatusCheckResponse', inverse_of: :merge_request
      has_many :approval_rules, class_name: 'ApprovalMergeRequestRule', inverse_of: :merge_request do
        def applicable_to_branch(branch)
          ActiveRecord::Associations::Preloader.new(
            records: self,
            associations: [:users, :groups, approval_project_rule: [:users, :groups, :protected_branches]]
          ).call

          self.select do |rule|
            next true unless rule.approval_project_rule.present?
            next true if rule.modified_from_project_rule

            rule.approval_project_rule.applies_to_branch?(branch)
          end
        end
      end
      has_many :approval_merge_request_rule_sources, through: :approval_rules
      has_many :approval_project_rules, through: :approval_merge_request_rule_sources
      has_one :merge_train_car, class_name: 'MergeTrains::Car', inverse_of: :merge_request, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

      has_many :blocks_as_blocker,
               class_name: 'MergeRequestBlock',
               foreign_key: :blocking_merge_request_id

      has_many :blocks_as_blockee,
               class_name: 'MergeRequestBlock',
               foreign_key: :blocked_merge_request_id

      has_many :blocking_merge_requests, through: :blocks_as_blockee

      has_many :blocked_merge_requests, through: :blocks_as_blocker

      has_many :compliance_violations, class_name: 'MergeRequests::ComplianceViolation'

      delegate :sha, to: :head_pipeline, prefix: :head_pipeline, allow_nil: true
      delegate :sha, to: :base_pipeline, prefix: :base_pipeline, allow_nil: true
      delegate :wrapped_approval_rules, :invalid_approvers_rules, to: :approval_state

      accepts_nested_attributes_for :approval_rules, allow_destroy: true

      scope :order_review_time_desc, -> do
        joins(:metrics).reorder(::MergeRequest::Metrics.review_time_field.asc.nulls_last)
      end

      scope :with_code_review_api_entity_associations, -> do
        preload(
          :author, :approved_by_users, :metrics,
          latest_merge_request_diff: :merge_request_diff_files, target_project: :namespace, milestone: :project)
      end

      scope :including_merge_train, -> do
        includes(:merge_train_car)
      end

      scope :with_head_pipeline, -> { where.not(head_pipeline_id: nil) }

      scope :for_projects_with_security_policy_project, -> do
        joins('INNER JOIN security_orchestration_policy_configurations ' \
              'ON merge_requests.target_project_id = security_orchestration_policy_configurations.project_id')
      end

      scope :with_applied_scan_result_policies, -> do
        joins(:approval_rules).merge(ApprovalMergeRequestRule.scan_finding)
      end

      after_update :sync_merge_request_compliance_violation, if: :saved_change_to_title?

      def sync_merge_request_compliance_violation
        compliance_violations.update_all(title: title)
      end

      def merge_requests_author_approval?
        !!target_project&.merge_requests_author_approval?
      end

      def merge_requests_disable_committers_approval?
        !!target_project&.merge_requests_disable_committers_approval?
      end
    end

    class_methods do
      # This is an ActiveRecord scope in CE
      def with_api_entity_associations
        super.preload(:blocking_merge_requests, :approval_rules,
                      target_project: [:regular_or_any_approver_approval_rules, group: :saml_provider])
      end

      def sort_by_attribute(method, *args, **kwargs)
        if method.to_s == 'review_time_desc'
          order_review_time_desc
        else
          super
        end
      end

      # Includes table keys in group by clause when sorting
      # preventing errors in postgres
      #
      # Returns an array of arel columns
      def grouping_columns(sort)
        grouping_columns = super
        grouping_columns << ::MergeRequest::Metrics.review_time_field if sort.to_s == 'review_time_desc'
        grouping_columns
      end

      # override
      def use_separate_indices?
        true
      end
    end

    override :predefined_variables
    def predefined_variables
      super.concat(merge_request_approval_variables)
    end

    override :mergeability_checks
    def mergeability_checks
      [
        ::MergeRequests::Mergeability::CheckApprovedService,
        ::MergeRequests::Mergeability::CheckDeniedPoliciesService,
        ::MergeRequests::Mergeability::CheckBlockedByOtherMrsService,
        ::MergeRequests::Mergeability::CheckExternalStatusChecksPassedService
      ] + super
    end

    override :merge_blocked_by_other_mrs?
    def merge_blocked_by_other_mrs?
      strong_memoize(:merge_blocked_by_other_mrs) do
        project.feature_available?(:blocking_merge_requests) &&
          blocking_merge_requests.any? { |mr| !mr.merged? }
      end
    end

    def on_train?
      merge_train_car&.active?
    end

    def allows_multiple_assignees?
      project.feature_available?(:multiple_merge_request_assignees)
    end

    def allows_multiple_reviewers?
      project.feature_available?(:multiple_merge_request_reviewers)
    end

    def visible_blocking_merge_requests(user)
      Ability.merge_requests_readable_by_user(blocking_merge_requests, user)
    end

    def visible_blocking_merge_request_refs(user)
      visible_blocking_merge_requests(user).map do |mr|
        mr.to_reference(target_project)
      end
    end

    # Unlike +visible_blocking_merge_requests+, this method doesn't include
    # blocking MRs that have been merged. This simplifies output, since we don't
    # need to tell the user that there are X hidden blocking MRs, of which only
    # Y are an obstacle. Pass include_merged: true to override this behaviour.
    def hidden_blocking_merge_requests_count(user, include_merged: false)
      hidden = blocking_merge_requests - visible_blocking_merge_requests(user)

      hidden.delete_if(&:merged?) unless include_merged

      hidden.count
    end

    def has_denied_policies?
      return false unless project.feature_available?(:license_scanning)

      return false unless actual_head_pipeline

      return false unless ::Gitlab::LicenseScanning
        .scanner_for_pipeline(project, actual_head_pipeline)
        .results_available?

      return false if has_approved_license_check?

      report_diff = compare_reports(::Ci::CompareLicenseScanningReportsService)

      licenses = report_diff.dig(:data, 'new_licenses')

      return false if licenses.nil? || licenses.empty?

      licenses.any? do |l|
        status = l.dig('classification', 'approval_status')
        'denied' == status
      end
    end

    def enabled_reports
      {
        sast: report_type_enabled?(:sast),
        container_scanning: report_type_enabled?(:container_scanning),
        dast: report_type_enabled?(:dast),
        dependency_scanning: report_type_enabled?(:dependency_scanning),
        license_scanning: report_type_enabled?(:license_scanning),
        coverage_fuzzing: report_type_enabled?(:coverage_fuzzing),
        secret_detection: report_type_enabled?(:secret_detection),
        api_fuzzing: report_type_enabled?(:api_fuzzing)
      }
    end

    def has_security_reports?
      !!actual_head_pipeline&.complete_and_has_reports?(::Ci::JobArtifact.security_reports)
    end

    def has_dependency_scanning_reports?
      !!actual_head_pipeline&.complete_and_has_reports?(::Ci::JobArtifact.of_report_type(:dependency_list))
    end

    def compare_dependency_scanning_reports(current_user)
      return missing_report_error("dependency scanning") unless has_dependency_scanning_reports?

      compare_reports(::Ci::CompareSecurityReportsService, current_user, 'dependency_scanning')
    end

    def has_container_scanning_reports?
      !!actual_head_pipeline&.complete_and_has_reports?(::Ci::JobArtifact.of_report_type(:container_scanning))
    end

    def compare_container_scanning_reports(current_user)
      return missing_report_error("container scanning") unless has_container_scanning_reports?

      compare_reports(::Ci::CompareSecurityReportsService, current_user, 'container_scanning')
    end

    def has_dast_reports?
      !!actual_head_pipeline&.complete_and_has_reports?(::Ci::JobArtifact.of_report_type(:dast))
    end

    def compare_dast_reports(current_user)
      return missing_report_error("DAST") unless has_dast_reports?

      compare_reports(::Ci::CompareSecurityReportsService, current_user, 'dast')
    end

    def compare_license_scanning_reports(current_user)
      unless ::Gitlab::LicenseScanning.scanner_for_pipeline(project, actual_head_pipeline).results_available?
        return missing_report_error("license scanning")
      end

      compare_reports(::Ci::CompareLicenseScanningReportsService, current_user)
    end

    def compare_license_scanning_reports_collapsed(current_user)
      unless ::Gitlab::LicenseScanning.scanner_for_pipeline(project, actual_head_pipeline).results_available?
        return missing_report_error("license scanning")
      end

      compare_reports(
        ::Ci::CompareLicenseScanningReportsCollapsedService,
        current_user,
        'license_scanning',
        additional_params: { license_check: approval_rules.license_compliance.any? }
      )
    end

    def has_metrics_reports?
      !!actual_head_pipeline&.complete_and_has_reports?(::Ci::JobArtifact.of_report_type(:metrics))
    end

    def compare_metrics_reports
      return missing_report_error("metrics") unless has_metrics_reports?

      compare_reports(::Ci::CompareMetricsReportsService)
    end

    def has_coverage_fuzzing_reports?
      !!actual_head_pipeline&.complete_and_has_reports?(::Ci::JobArtifact.of_report_type(:coverage_fuzzing))
    end

    def compare_coverage_fuzzing_reports(current_user)
      return missing_report_error("coverage fuzzing") unless has_coverage_fuzzing_reports?

      compare_reports(::Ci::CompareSecurityReportsService, current_user, 'coverage_fuzzing')
    end

    def has_api_fuzzing_reports?
      !!actual_head_pipeline&.complete_and_has_reports?(::Ci::JobArtifact.of_report_type(:api_fuzzing))
    end

    def compare_api_fuzzing_reports(current_user)
      return missing_report_error('api fuzzing') unless has_api_fuzzing_reports?

      compare_reports(::Ci::CompareSecurityReportsService, current_user, 'api_fuzzing')
    end

    override :use_merge_base_pipeline_for_comparison?
    def use_merge_base_pipeline_for_comparison?(service_class)
      !!USES_MERGE_BASE_PIPELINE_FOR_COMPARISON[service_class]&.call(project)
    end

    def synchronize_approval_rules_from_target_project
      return if merged?

      project_rules = target_project.approval_rules.report_approver.includes(:users, :groups)
      project_rules.find_each do |project_rule|
        project_rule.apply_report_approver_rules_to(self)
      end
    end

    def sync_project_approval_rules_for_policy_configuration(configuration_id)
      return if merged?

      project_rules = target_project
        .approval_rules
        .report_approver
        .for_policy_configuration(configuration_id)
        .includes(:users, :groups)

      project_rules.find_each do |project_rule|
        project_rule.apply_report_approver_rules_to(self)
      end
    end

    def applicable_approval_rules_for_user(user_id)
      wrapped_approval_rules.select do |rule|
        rule.approvers.pluck(:id).include?(user_id)
      end
    end

    def security_reports_up_to_date?
      project.security_reports_up_to_date_for_ref?(target_branch)
    end

    def audit_details
      title
    end

    def latest_pipeline_for_target_branch
      @latest_pipeline ||= project.ci_pipelines
          .order(id: :desc)
          .find_by(ref: target_branch)
    end

    override :can_suggest_reviewers?
    def can_suggest_reviewers?
      open? && modified_paths.any?
    end

    override :suggested_reviewer_users
    def suggested_reviewer_users
      return ::User.none unless predictions && predictions.suggested_reviewers.is_a?(Hash)

      usernames = Array.wrap(suggested_reviewers["reviewers"])
      return ::User.none if usernames.empty?

      # Preserve the original order of suggested usernames
      join_sql = ::MergeRequest.sanitize_sql_array(
        [
          'JOIN UNNEST(ARRAY[?]::varchar[]) WITH ORDINALITY AS t(username, ord) USING(username)',
          usernames
        ]
      )

      project.authorized_users.with_state(:active).humans
        .joins(Arel.sql(join_sql))
        .order('t.ord')
    end

    private

    def has_approved_license_check?
      if rule = approval_rules.license_compliance.last
        ApprovalWrappedRule.wrap(self, rule).approved?
      end
    end

    def merge_request_approval_variables
      return unless approval_feature_available?

      strong_memoize(:merge_request_approval_variables) do
        ::Gitlab::Ci::Variables::Collection.new.tap do |variables|
          variables.append(key: 'CI_MERGE_REQUEST_APPROVED', value: approved?.to_s) if approved?
        end
      end
    end
  end
end
