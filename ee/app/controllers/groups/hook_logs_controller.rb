# frozen_string_literal: true

module Groups
  class HookLogsController < Groups::ApplicationController
    before_action :authorize_admin_group!

    include ::WebHooks::HookLogActions

    layout 'group_settings'

    private

    def hook
      @hook ||= @group.hooks.find(params[:hook_id])
    end

    def after_retry_redirect_path
      edit_group_hook_path(@group, hook)
    end
  end
end
