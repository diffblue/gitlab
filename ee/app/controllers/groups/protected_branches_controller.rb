# frozen_string_literal: true

module Groups
  class ProtectedBranchesController < Groups::ApplicationController
    include ProtectedBranchesHelper

    before_action :check_feature_available!
    before_action :authorize_admin_group!
    before_action :load_protected_branch, only: %i[update destroy]

    feature_category :source_code_management

    def create
      protected_branch = ::ProtectedBranches::CreateService.new(group, current_user, protected_branch_params).execute
      flash[:alert] = protected_branch.errors.full_messages.join(', ') unless protected_branch.persisted?

      respond_to do |format|
        format.html { redirect_to_repository_settings }
        format.json { head :ok }
      end
    end

    def update
      service = ::ProtectedBranches::UpdateService.new(group, current_user, protected_branch_params)
      @protected_branch = service.execute(@protected_branch)

      if @protected_branch.valid?
        render json: @protected_branch, status: :ok, include: access_levels
      else
        render json: @protected_branch.errors, status: :unprocessable_entity
      end
    end

    def destroy
      ::ProtectedBranches::DestroyService.new(group, current_user).execute(@protected_branch)

      respond_to do |format|
        format.html { redirect_to_repository_settings }
        format.js { head :ok }
      end
    end

    private

    def check_feature_available!
      render_404 unless group_protected_branches_feature_available?(group)
      render_404 unless can_admin_group_protected_branches?(group)
    end

    def load_protected_branch
      @protected_branch = group.protected_branches.find(params[:id])
    end

    def redirect_to_repository_settings
      redirect_to group_settings_repository_path(group, anchor: params[:update_section])
    end

    def access_levels
      [:merge_access_levels, :push_access_levels]
    end

    def protected_branch_params(*attrs)
      attrs = ([:name,
                :allow_force_push,
                :code_owner_approval_required,
                { merge_access_levels_attributes: access_level_attributes,
                  push_access_levels_attributes: access_level_attributes }] + attrs).uniq

      unless group.licensed_feature_available?(:code_owner_approval_required)
        params[:code_owner_approval_required] = false
      end

      params.require(:protected_branch).permit(attrs)
    end

    def access_level_attributes
      %i[access_level id _destroy]
    end
  end
end
