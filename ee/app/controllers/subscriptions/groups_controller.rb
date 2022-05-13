# frozen_string_literal: true

module Subscriptions
  class GroupsController < ApplicationController
    include RoutableActions

    layout 'checkout'

    before_action :find_group

    feature_category :purchase
    urgency :low

    def edit
    end

    def update
      if Groups::UpdateService.new(@group, current_user, group_params).execute
        notice = if params[:new_user] == 'true'
                   _('Welcome to GitLab, %{first_name}!' % { first_name: current_user.first_name })
                 else
                   _('Subscription successfully applied to "%{group_name}"' % { group_name: @group.name })
                 end

        redirect_to group_path(@group), notice: notice
      else
        @group.path = @group.path_before_last_save || @group.path_was
        render action: :edit
      end
    end

    private

    def find_group
      @group ||= find_routable!(Group, params[:id], request.fullpath)
    end

    def group_params
      params.require(:group).permit(:name, :path, :visibility_level)
    end

    def build_canonical_path(group)
      url_for(safe_params.merge(id: group.to_param))
    end
  end
end
