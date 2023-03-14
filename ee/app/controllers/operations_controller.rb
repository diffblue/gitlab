# frozen_string_literal: true

# Note: Both Operations dashboard (https://docs.gitlab.com/ee/user/operations_dashboard/) and Environments dashboard (https://docs.gitlab.com/ee/ci/environments/environments_dashboard.html) features are co-existing in the same controller.
class OperationsController < ApplicationController
  before_action :authorize_read_operations_dashboard!

  feature_category :release_orchestration
  urgency :low

  POLLING_INTERVAL = 120_000

  # Used by Operations dashboard.
  def index
    respond_to do |format|
      format.html

      format.json do
        set_polling_interval_header
        projects = load_projects

        render json: { projects: serialize_as_json(projects) }
      end
    end
  end

  # Used by Environments dashboard.
  def environments
    respond_to do |format|
      format.html

      format.json do
        set_polling_interval_header
        projects = load_environments_projects

        render json: { projects: serialize_as_json_for_environments(projects) }
      end
    end
  end

  # Used by Operations and Environments dashboard.
  def create
    respond_to do |format|
      format.json do
        project_ids = params['project_ids']

        result = add_projects(project_ids)

        render json: {
          added: result.added_project_ids,
          duplicate: result.duplicate_project_ids,
          invalid: result.invalid_project_ids
        }
      end
    end
  end

  # Used by Operations and Environments dashboard.
  def destroy
    project_id = params['project_id']

    if remove_project(project_id)
      head :ok
    else
      head :no_content
    end
  end

  private

  def authorize_read_operations_dashboard!
    render_404 unless can?(current_user, :read_operations_dashboard)
  end

  def set_polling_interval_header
    Gitlab::PollingInterval.set_header(response, interval: POLLING_INTERVAL)
  end

  def load_projects
    Dashboard::Operations::ListService.new(current_user).execute
  end

  def load_environments_projects
    Dashboard::Environments::ListService.new(current_user).execute
  end

  def add_projects(project_ids)
    Dashboard::Projects::CreateService.new(
      current_user,
      current_user.ops_dashboard_projects,
      feature: :operations_dashboard
    ).execute(project_ids)
  end

  def remove_project(project_id)
    UsersOpsDashboardProjects::DestroyService.new(current_user).execute(project_id)
  end

  def serialize_as_json(projects)
    DashboardOperationsSerializer.new(current_user: current_user).represent(projects)
  end

  def serialize_as_json_for_environments(projects)
    DashboardEnvironmentsSerializer
      .new(current_user: current_user)
      .with_pagination(request, response)
      .represent(projects)
  end
end

OperationsController.prepend_mod
