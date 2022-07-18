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
      ].freeze

      override :execute
      def execute
        limit = params.delete(:repository_size_limit)
        wiki_was_enabled = project.wiki_enabled?

        shared_runners_setting
        mirror_user_setting
        compliance_framework_setting

        return update_failed! if project.errors.any?

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
        end

        result
      end

      private

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
        EE::Audit::ProjectChangesAuditor.new(current_user, project).execute
      end

      def sync_wiki_on_enable
        ::Geo::RepositoryUpdatedService.new(project.wiki.repository).execute
      end

      def refresh_merge_trains(project)
        return unless project.merge_pipelines_were_disabled?

        MergeTrain.first_cars_in_trains(project).each do |car|
          MergeTrains::RefreshWorker.perform_async(car.target_project_id, car.target_branch)
        end
      end
    end
  end
end
