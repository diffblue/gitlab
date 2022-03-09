# frozen_string_literal: true

class Projects::Ci::SecureFilesController < Projects::ApplicationController
  before_action :check_can_collaborate!

  feature_category :pipeline_authoring

  def show
  end

  private

  def check_can_collaborate!
    render_404 unless can?(current_user, :read_secure_files, project)
  end
end
