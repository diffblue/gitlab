# frozen_string_literal: true

module Iterations
  class CreateService
    include Gitlab::Allowable
    include Gitlab::Utils::StrongMemoize

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

      if cadence_uses_automatic_scheduling?
        return ::ServiceResponse.error(
          message: _('Iteration cannot be created for cadence'),
          payload: {
            errors: [_('Iterations cannot be manually added to cadences that use automatic scheduling')]
          })
      end

      iteration = parent.iterations.new(params)
      iteration.set_iterations_cadence

      if iteration.save
        ::ServiceResponse.success(message: _('New iteration created'), payload: { iteration: iteration })
      else
        ::ServiceResponse.error(message: _('Error creating new iteration'), payload: {
                                  errors: iteration.errors.full_messages
                                })
      end
    rescue ActiveRecord::RecordNotFound => e
      ::ServiceResponse.error(message: _('Iterations cadence not found'),
                              payload: { errors: [e.message] }, http_status: 404)
    end

    private

    def cadence_uses_automatic_scheduling?
      return false unless cadence

      cadence.automatic?
    end

    def cadence
      strong_memoize(:cadence) do
        next if params[:iterations_cadence_id].blank?

        Iterations::Cadence.find(params[:iterations_cadence_id])
      end
    end
  end
end
