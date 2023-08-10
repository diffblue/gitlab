# frozen_string_literal: true

module TargetBranchRules
  class BaseService < ::BaseService
    attr_reader :project, :current_user, :params

    # project - The project the target branch rule is for
    # current_user - The user that performs the action
    # params - A hash of parameters
    def initialize(project, current_user, params = {})
      @project = project
      @current_user = current_user
      @params = params
    end
  end
end
