# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'devise/registrations/new', feature_category: :authentication_and_authorization do
  let(:arkose_enabled_for_signup) { true }
  let(:arkose_labs_api_key) { "api-key" }
  let(:arkose_labs_domain) { "domain" }

  subject { render(template: 'devise/registrations/new') }

  before do
    stub_devise

    allow(::Arkose::Settings).to receive(:enabled_for_signup?).and_return(arkose_enabled_for_signup)
    allow(::Arkose::Settings).to receive(:arkose_public_api_key).and_return(arkose_labs_api_key)
    allow(::Arkose::Settings).to receive(:arkose_labs_domain).and_return(arkose_labs_domain)
  end

  it 'renders challenge container with the correct data attributes', :aggregate_failures do
    subject

    expect(rendered).to have_selector('#js-arkose-labs-challenge')
    expect(rendered).to have_selector("[data-api-key='#{arkose_labs_api_key}']")
    expect(rendered).to have_selector("[data-domain='#{arkose_labs_domain}']")
  end

  context 'when the feature is disabled' do
    let(:arkose_enabled_for_signup) { false }

    it 'does not render challenge container', :aggregate_failures do
      subject

      expect(rendered).not_to have_selector('#js-arkose-labs-challenge')
      expect(rendered).not_to have_selector("[data-api-key='#{arkose_labs_api_key}']")
      expect(rendered).not_to have_selector("[data-domain='#{arkose_labs_domain}']")
    end
  end

  def stub_devise
    allow(view).to receive(:devise_mapping).and_return(Devise.mappings[:user])
    allow(view).to receive(:resource).and_return(build(:user))
    allow(view).to receive(:resource_name).and_return(:user)
    allow(view).to receive(:glm_tracking_params).and_return({})
  end
end
