# frozen_string_literal: true

module Subscriptions
  class NewPlanPresenter < Gitlab::View::Presenter::Delegated
    presents ::Plan

    NEW_PLAN_TITLES = {
      silver: 'Premium (Formerly Silver)',
      gold: 'Ultimate (Formerly Gold)'
    }.freeze

    delegator_override :title
    def title
      NEW_PLAN_TITLES.fetch(plan_key, super)
    end

    private

    def plan_key
      name&.to_sym
    end
  end
end
