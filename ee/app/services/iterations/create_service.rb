# frozen_string_literal: true

module Iterations
  class CreateService
    include Gitlab::Allowable

    # Parent can either a group or a project
    attr_accessor :parent, :current_user, :params

    def initialize(parent, user, params = {})
      @parent = parent
      @current_user = user
      @params = params.dup
    end

    def execute
      return ::ServiceResponse.error(message: _('Operation not allowed'), http_status: 403) unless
          parent.feature_available?(:iterations) && can?(current_user, :create_iteration, parent)

      iteration = parent.iterations.new(params)
      iteration.set_iterations_cadence

      if iteration.save
        ::ServiceResponse.success(message: _('New iteration created'), payload: { iteration: iteration })
      else
        ::ServiceResponse.error(message: _('Error creating new iteration'), payload: { errors: iteration.errors })
      end
    end
  end
end
