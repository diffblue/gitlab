# frozen_string_literal: true

module EE
  module Projects
    module UpdateService
      extend ::Gitlab::Utils::Override

      PULL_MIRROR_ATTRIBUTES = %i[
        mirror
        mirror_user_id
        import_url
        username_only_import_url
        mirror_trigger_builds
        only_mirror_protected_branches
        mirror_overwrites_diverged_branches
        import_data_attributes
        mirror_branch_regex
      ].freeze

      override :execute
      def execute
        limit = params.delete(:repository_size_limit)
        wiki_was_enabled = project.wiki_enabled?

        shared_runners_setting
        mirror_user_setting
        mirror_branch_setting
        compliance_framework_setting

        return update_failed! if project.errors.any?

        if params[:project_setting_attributes].present?
          suggested_reviewers_already_enabled = project.suggested_reviewers_enabled
          unless project.suggested_reviewers_available?
            params[:project_setting_attributes].delete(:suggested_reviewers_enabled)
          end
        end

        prepare_analytics_dashboards_params!

        result = super do
          # Repository size limit comes as MB from the view
          project.repository_size_limit = ::Gitlab::Utils.try_megabytes_to_bytes(limit) if limit
        end

        if result[:status] == :success
          refresh_merge_trains(project)

          log_audit_events

          sync_wiki_on_enable if !wiki_was_enabled && project.wiki_enabled?
          project.import_state.force_import_job! if params[:mirror].present? && project.mirror?
          project.remove_import_data if project.previous_changes.include?('mirror') && !project.mirror?

          if suggested_reviewers_already_enabled
            trigger_project_deregistration
          else
            trigger_project_registration
          end
        end

        result
      end

      private

      def prepare_analytics_dashboards_params!
        if params[:analytics_dashboards_pointer_attributes] &&
            params[:analytics_dashboards_pointer_attributes][:target_project_id].blank?

          params[:analytics_dashboards_pointer_attributes][:_destroy] = true
          params[:analytics_dashboards_pointer_attributes].delete(:target_project_id)
        end
      end

      def trigger_project_registration
        return unless params[:project_setting_attributes].present? &&
          params[:project_setting_attributes][:suggested_reviewers_enabled] == '1'

        return unless can_update_suggested_reviewers_setting?

        ::Projects::RegisterSuggestedReviewersProjectWorker.perform_async(project.id, current_user.id)
      end

      def trigger_project_deregistration
        return unless params[:project_setting_attributes].present? &&
          params[:project_setting_attributes][:suggested_reviewers_enabled] == '0'

        return unless project.suggested_reviewers_available?

        ::Projects::DeregisterSuggestedReviewersProjectWorker.perform_async(project.id, current_user.id)
      end

      def can_update_suggested_reviewers_setting?
        project.suggested_reviewers_available? && current_user.can?(:create_resource_access_tokens, project)
      end

      override :remove_unallowed_params
      def remove_unallowed_params
        super

        unless project.licensed_feature_available?(:external_status_checks)
          params.delete(:only_allow_merge_if_all_status_checks_passed)
        end
      end

      override :after_default_branch_change
      def after_default_branch_change(previous_default_branch)
        ::AuditEventService.new(
          current_user,
          project,
          action: :custom,
          custom_message: "Default branch changed from #{previous_default_branch} to #{project.default_branch}"
        ).for_project.security_event
      end

      # A user who enables shared runners must meet the credit card requirement if
      # there is one.
      def shared_runners_setting
        return unless params[:shared_runners_enabled]
        return if project.shared_runners_enabled

        unless current_user.has_required_credit_card_to_enable_shared_runners?(project)
          project.errors.add(:shared_runners_enabled, _('cannot be enabled until a valid credit card is on file'))
        end
      end

      # A user who changes any aspect of pull mirroring settings must be made
      # into the mirror user, to prevent them from acquiring capabilities
      # owned by the previous user, such as writing to a protected branch.
      #
      # Only admins can set the mirror user to be an arbitrary user.
      def mirror_user_setting
        return unless PULL_MIRROR_ATTRIBUTES.any? { |symbol| params.key?(symbol) }

        if params[:mirror_user_id] && params[:mirror_user_id] != project.mirror_user_id
          project.errors.add(:mirror_user_id, 'is invalid') unless current_user&.admin?
        else
          params[:mirror_user_id] = current_user.id
        end
      end

      def mirror_branch_setting
        if mirror_branch_regex_enabled? && params[:mirror_branch_regex].present?
          params[:only_mirror_protected_branches] = false
        end

        params.delete(:mirror_branch_regex) unless mirror_branch_regex_enabled?

        params[:mirror_branch_regex] = nil if params[:only_mirror_protected_branches]
      end

      def mirror_branch_regex_enabled?
        ::Feature.enabled?(:mirror_only_branches_match_regex, project)
      end

      def compliance_framework_setting
        settings = params[:compliance_framework_setting_attributes]
        return unless settings.present?

        if can?(current_user, :admin_compliance_framework, project)
          framework_identifier = settings.delete(:framework)
          if framework_identifier.blank?
            settings.merge!(_destroy: true)
          else
            settings[:compliance_management_framework] = project.namespace.root_ancestor.compliance_management_frameworks.find(framework_identifier)
          end
        else
          params.delete(:compliance_framework_setting_attributes)
        end
      end

      def log_audit_events
        Audit::ProjectChangesAuditor.new(current_user, project).execute
      end

      def sync_wiki_on_enable
        if ::Geo::ProjectWikiRepositoryReplicator.enabled?
          project.wiki_repository.replicator.handle_after_update if project.wiki_repository
        else
          ::Geo::RepositoryUpdatedService.new(project.wiki.repository).execute
        end
      end

      def refresh_merge_trains(project)
        return unless project.merge_pipelines_were_disabled?

        MergeTrains::Car.first_cars_in_trains(project).each do |car|
          MergeTrains::RefreshWorker.perform_async(car.target_project_id, car.target_branch)
        end
      end
    end
  end
end
