# frozen_string_literal: true

module EE
  module UsersController
    extend ::Gitlab::Utils::Override

    def available_project_templates
      load_custom_project_templates
    end

    def available_group_templates
      load_group_project_templates
    end

    private

    override :personal_projects
    def personal_projects
      super.with_compliance_framework_settings
    end

    override :contributed_projects
    def contributed_projects
      super.with_compliance_framework_settings
    end

    override :starred_projects
    def starred_projects
      super.with_compliance_framework_settings
    end

    # Even though available templates endpoints accept a user
    # We don't allow fetching the templates for arbitrary user
    # The endpoints are going to be removed in
    # https://gitlab.com/gitlab-org/gitlab/-/issues/345897
    def load_custom_project_templates
      render_404 unless user == current_user

      @custom_project_templates ||= user.available_custom_project_templates(search: params[:search]).page(params[:page]) # rubocop:disable Gitlab/ModuleWithInstanceVariables
    end

    def load_group_project_templates
      render_404 unless user == current_user

      @groups_with_project_templates ||= # rubocop:disable Gitlab/ModuleWithInstanceVariables
        user.available_subgroups_with_custom_project_templates(params[:group_id])
            .page(params[:page])
    end
  end
end
