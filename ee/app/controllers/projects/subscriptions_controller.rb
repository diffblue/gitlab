# frozen_string_literal: true

class Projects::SubscriptionsController < Projects::ApplicationController
  include ::Gitlab::Utils::StrongMemoize

  before_action :authorize_admin_project!
  before_action :feature_ci_project_subscriptions!
  before_action :authorize_upstream_project!, only: [:create]

  feature_category :continuous_integration
  urgency :low

  def create
    subscription = project.upstream_project_subscriptions.create(
      upstream_project: upstream_project,
      author: current_user
    )

    if subscription.persisted?
      flash[:notice] = _('Subscription successfully created.')
    else
      flash[:alert] = subscription.errors.full_messages
    end

    redirect_to project_settings_ci_cd_path(project)
  end

  def destroy
    flash[:notice] = if project_subscription&.destroy
                       _('Subscription successfully deleted.')
                     else
                       _('Subscription deletion failed.')
                     end

    redirect_to project_settings_ci_cd_path(project), status: :found
  end

  private

  def upstream_project
    strong_memoize(:upstream_project) do
      Project.find_by_full_path(params[:upstream_project_path])
    end
  end

  def project_subscription
    project.upstream_project_subscriptions.find(params[:id])
  end

  def feature_ci_project_subscriptions!
    render_404 unless project.feature_available?(:ci_project_subscriptions)
  end

  def authorize_upstream_project!
    return if can?(current_user, :developer_access, upstream_project)

    flash[:warning] = _('This project path either does not exist or you do not have access.')
    redirect_to project_settings_ci_cd_path(project)
  end
end
