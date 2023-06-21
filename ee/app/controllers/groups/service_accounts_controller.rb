# frozen_string_literal: true

module Groups
  class ServiceAccountsController < Groups::ApplicationController
    include GroupsHelper

    feature_category :user_management

    before_action :authorize_service_accounts!

    def index; end

    private

    def authorize_service_accounts!
      render_404 unless Feature.enabled?(:service_accounts_crud, @group) && can_admin_group_member?(@group)
    end
  end
end
