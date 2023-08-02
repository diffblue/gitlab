# frozen_string_literal: true

module EE
  module UsersController
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      include GeoInstrumentation

      feature_category :user_profile, [:available_group_templates]

      feature_category :source_code_management, [:available_project_templates]

      urgency :low, [:available_group_templates]
      before_action :ensure_user_is_current_user!, only: [:available_project_templates, :available_group_templates]
    end

    # Even though available templates endpoints accept a user
    # We don't allow fetching the templates for arbitrary user
    # The endpoints are going to be removed in
    # https://gitlab.com/gitlab-org/gitlab/-/issues/345897
    def available_project_templates
      @custom_project_templates = # rubocop:disable Gitlab/ModuleWithInstanceVariables
        user.available_custom_project_templates(search: params[:search]).page(params[:page])

      render layout: false
    end

    def available_group_templates
      @target_group = # rubocop:disable Gitlab/ModuleWithInstanceVariables
        GroupFinder.new(current_user).execute(id: params[:group_id])

      @groups_with_project_templates = # rubocop:disable Gitlab/ModuleWithInstanceVariables
        user.available_subgroups_with_custom_project_templates(params[:group_id])
          .page(params[:page])
          # Workaround: to generate correct COUNT sql:
          # https://gitlab.com/gitlab-org/gitlab/-/issues/381077
          .tap { |t| t.total_count("#{::Namespace.table_name}.#{::Namespace.primary_key}") }

      render layout: false
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

    def ensure_user_is_current_user!
      render_404 unless user == current_user
    end
  end
end
