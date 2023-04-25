# frozen_string_literal: true

module Llm
  class TanukiBotController < ApplicationController
    wrap_parameters format: []
    feature_category :global_search

    before_action :verify_tanuki_bot_enabled

    def ask
      respond_to do |format|
        format.json { render json: generate_response, status: :ok }
        format.any { head :bad_request }
      end
    end

    private

    def verify_tanuki_bot_enabled
      return if ::Gitlab::Llm::TanukiBot.enabled_for?(user: current_user)

      head :unauthorized
    end

    def generate_response
      ::Gitlab::Llm::TanukiBot.execute(current_user: current_user, question: params.require(:q))
    end
  end
end
