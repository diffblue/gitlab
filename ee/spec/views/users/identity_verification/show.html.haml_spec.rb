# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'users/identity_verification/show' do
  let_it_be(:user) { build_stubbed(:user) }

  let(:form_id) { 'form_id' }

  before do
    allow(view).to receive(:current_user).and_return(user)

    stub_const("::Gitlab::SubscriptionPortal::REGISTRATION_VALIDATION_FORM_ID", form_id)
  end

  it 'renders the identity verification app root with the correct data attributes', :aggregate_failures do
    render

    expect(rendered).to have_selector('#js-identity-verification')

    expect(rendered).to have_selector("[data-credit-card-form-id='#{form_id}']")
    expect(rendered).to have_selector(
      "[data-credit-card-completed='#{!user.requires_credit_card_verification}']"
    )
  end
end
