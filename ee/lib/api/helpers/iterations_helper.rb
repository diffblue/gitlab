# frozen_string_literal: true

module API
  module Helpers
    module IterationsHelper
      def adjust_deprecated_state
        params[:state] = "current" if params[:state].present? && params[:state].to_s == "started"
      end
    end
  end
end
