# frozen_string_literal: true

module RemoteDevelopment
  class WorkspacesController < ApplicationController
    before_action :authorize_remote_development!, only: [:index]

    feature_category :remote_development
    urgency :low

    def index; end

    private

    def authorize_remote_development!
      render_404 unless can?(current_user, :read_workspace)
    end
  end
end
