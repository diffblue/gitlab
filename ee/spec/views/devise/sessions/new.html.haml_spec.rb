# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'devise/sessions/new' do
  before do
    view.instance_variable_set(:@arkose_labs_public_key, "arkose-api-key")
    view.instance_variable_set(:@arkose_labs_domain, "gitlab-api.arkoselab.com")
  end

  describe 'ArkoseLabs challenge' do
    subject { render(template: 'devise/sessions/new', layout: 'layouts/devise') }

    before do
      stub_devise
      disable_captcha
      allow(Gitlab).to receive(:com?).and_return(true)
    end

    context 'when the :arkose_labs_login_challenge feature flag is enabled' do
      before do
        stub_feature_flags(arkose_labs_login_challenge: true)

        subject
      end

      it 'renders the challenge container' do
        expect(rendered).to have_css('#js-arkose-labs-challenge')
      end

      it 'passes the API key to the challenge container' do
        expect(rendered).to have_selector('#js-arkose-labs-challenge[data-api-key="arkose-api-key"]')
      end

      it 'passes the ArkoseLabs domain to the challenge container' do
        expect(rendered).to have_selector('#js-arkose-labs-challenge[data-domain="gitlab-api.arkoselab.com"]')
      end
    end

    context 'when the :arkose_labs_login_challenge feature flag is disabled' do
      before do
        stub_feature_flags(arkose_labs_login_challenge: false)

        subject
      end

      it 'does not render challenge container' do
        expect(rendered).not_to have_css('#js-arkose-labs-challenge')
      end
    end
  end

  def stub_devise
    allow(view).to receive(:devise_mapping).and_return(Devise.mappings[:user])
    allow(view).to receive(:resource).and_return(spy)
    allow(view).to receive(:resource_name).and_return(:user)
  end

  def disable_captcha
    allow(view).to receive(:captcha_enabled?).and_return(false)
    allow(view).to receive(:captcha_on_login_required?).and_return(false)
  end
end
