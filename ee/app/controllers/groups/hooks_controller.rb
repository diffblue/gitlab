# frozen_string_literal: true

class Groups::HooksController < Groups::ApplicationController
  include ::Integrations::HooksExecution

  # Authorize
  before_action :group
  before_action :authorize_admin_group!
  before_action :check_group_webhooks_available!
  before_action :set_hook, only: [:edit, :update, :test, :destroy]
  before_action -> { check_rate_limit!(:group_testing_hook, scope: [@group, current_user]) }, only: :test

  respond_to :html

  layout 'group_settings'

  feature_category :integrations
  urgency :low, [:test]

  def index
    @hooks = @group.hooks.load
    @hook = GroupHook.new
  end

  def create
    @hook = @group.hooks.new(hook_params)
    @hook.save

    if @hook.valid?
      redirect_to group_hooks_path(@group)
    else
      @hooks = @group.hooks.select(&:persisted?)
      render :index
    end
  end

  def edit
  end

  def update
    if @hook.update(hook_params)
      flash[:notice] = _('Hook was successfully updated.')
      redirect_to group_hooks_path(@group)
    else
      render 'edit'
    end
  end

  def test
    if @group.first_non_empty_project
      service = TestHooks::ProjectService.new(@hook, current_user, params[:trigger] || 'push_events')
      service.project = @group.first_non_empty_project
      result = service.execute

      set_hook_execution_notice(result)
    else
      flash[:alert] = _('Hook execution failed. Ensure the group has a project with commits.')
    end

    redirect_back_or_default(default: { action: 'index' })
  end

  def destroy
    destroy_hook(@hook)

    redirect_to group_hooks_path(@group), status: :found
  end

  private

  def set_hook
    @hook ||= @group.hooks.find(params[:id])
  end

  def hook_params
    params.require(:hook).permit(
      :enable_ssl_verification,
      :token,
      :url,
      :push_events_branch_filter,
      *GroupHook.triggers.values
    )
  end

  def check_group_webhooks_available!
    render_404 unless @group.licensed_feature_available?(:group_webhooks) || LicenseHelper.show_promotions?(current_user)
  end
end
