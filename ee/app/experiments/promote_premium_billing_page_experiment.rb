# frozen_string_literal: true

class PromotePremiumBillingPageExperiment < ApplicationExperiment
  exclude :paid_plan

  private

  def paid_plan
    context.namespace.paid?
  end
end
