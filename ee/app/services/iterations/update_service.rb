# frozen_string_literal: true

module Iterations
  class UpdateService
    include Gitlab::Allowable

    IGNORED_KEYS = %i[group_path id state_enum state].freeze

    attr_accessor :parent, :current_user, :params

    def initialize(parent, user, params = {})
      @parent = parent
      @current_user = user
      @params = params.dup
    end

    def execute(iteration)
      return ::ServiceResponse.error(message: _('Operation not allowed'), http_status: 403) unless allowed?

      iteration.assign_attributes(params.except(*IGNORED_KEYS))

      if iteration.save
        ::ServiceResponse.success(message: _('Iteration updated'), payload: { iteration: iteration })
      else
        ::ServiceResponse.error(message: _('Error creating new iteration'), payload: { errors: iteration.errors.full_messages })
      end
    end

    private

    def allowed?
      parent.feature_available?(:iterations) && can?(current_user, :admin_iteration, parent)
    end
  end
end
