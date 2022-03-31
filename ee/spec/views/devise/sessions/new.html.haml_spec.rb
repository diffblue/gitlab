# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'devise/sessions/new' do
  before do
    view.instance_variable_set(:@arkose_labs_public_key, "arkose-api-key")
  end

  describe 'ArkoseLabs challenge' do
    subject { render(template: 'devise/sessions/new', layout: 'layouts/devise') }

    before do
      stub_devise
      disable_captcha
      allow(Gitlab).to receive(:com?).and_return(true)
    end

    context 'when arkose_labs_enabled? is enabled' do
      before do
        stub_arkose_labs(enabled: true)

        subject
      end

      it 'renders the challenge container' do
        expect(rendered).to have_css('.js-arkose-labs-challenge')
      end

      it 'passes the API key to the challenge container' do
        expect(rendered).to have_selector('.js-arkose-labs-challenge[data-api-key="arkose-api-key"]')
      end
    end

    context 'when arkose_labs_enabled? is disabled' do
      before do
        stub_arkose_labs(enabled: false)

        subject
      end

      it 'does not render challenge container' do
        expect(rendered).not_to have_css('.js-arkose-labs-challenge')
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

  def stub_arkose_labs(enabled:)
    allow(view).to receive(:arkose_labs_enabled?).and_return(enabled)
  end
end
