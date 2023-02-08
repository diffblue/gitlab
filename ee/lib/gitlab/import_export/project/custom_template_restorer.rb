# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Project
      class CustomTemplateRestorer
        def initialize(project:, shared:, user:)
          @project = project
          @shared = shared
          @user = user
          @source_project_id = @project.import_data&.data&.fetch("template_project_id", nil)
          set_source
        end

        def restore
          return true if @source_project.nil?
          return true unless @project.gitlab_custom_project_template_import?

          [hooks_restorer].all?(&:restore)
        end

        private

        def set_source
          # It is ok to use ::Project.find because
          # we check later if user is source project owner
          # and import_data cannot be set by user via the import files
          return unless @source_project_id

          @source_project = ::Project.find(@source_project_id)
          return if user_can_admin_source?

          @source_project = nil
        end

        def user_can_admin_source?
          @user.can_admin_all_resources? || @user.can?(:owner_access, @source_project)
        end

        def hooks_restorer
          ProjectHooksRestorer.new(project: @project, shared: @shared, user: @user, source: @source_project)
        end
      end
    end
  end
end
