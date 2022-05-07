# frozen_string_literal: true

#  We write these in helper methods so that JH can override them
#  Related issue: https://gitlab.com/gitlab-org/gitlab/-/issues/361718
module BillingPlansHelpers
  def should_have_hand_raise_lead_button
    expect(page).to have_selector(
      ".js-hand-raise-lead-button[data-namespace-id='#{namespace.id}'][data-user-name='#{user.username}']",
      visible: false)
  end

  def click_premium_contact_sales_button_and_submit_form
    page.within('[data-testid="plan-card-premium"]') do
      click_button 'Contact sales'
    end

    fill_hand_raise_lead_form_and_submit
  end
end

BillingPlansHelpers.prepend_mod
