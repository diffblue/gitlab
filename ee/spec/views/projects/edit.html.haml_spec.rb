# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/edit' do
  let(:project) { create(:project) }
  let(:user) { create(:admin) }

  before do
    assign(:project, project)

    allow(controller).to receive(:current_user).and_return(user)
    allow(view).to receive_messages(current_user: user,
                                    can?: true,
                                    current_application_settings: Gitlab::CurrentSettings.current_application_settings)
  end

  context 'status checks' do
    context 'feature is not available' do
      before do
        stub_licensed_features(external_status_checks: false)

        render
      end

      it 'hides the status checks area' do
        expect(rendered).not_to have_content('Status check')
      end

      context 'feature is available' do
        before do
          stub_licensed_features(external_status_checks: true)

          render
        end

        it 'shows the status checks area' do
          expect(rendered).to have_content('Status check')
        end
      end
    end
  end

  describe 'prompt user about registration features' do
    let(:message) { s_("RegistrationFeatures|Want to %{feature_title} for free?") % { feature_title: s_('RegistrationFeatures|use this feature') } }

    context 'with no license and service ping disabled' do
      before do
        allow(License).to receive(:current).and_return(nil)
        stub_application_setting(usage_ping_enabled: false)

        render
      end

      it 'renders registration features CTA' do
        expect(rendered).to have_content(message)
        expect(rendered).to have_link(s_('RegistrationFeatures|Registration Features Program'))
        expect(rendered).to have_link(s_('RegistrationFeatures|Enable Service Ping and register for this feature.'))
        expect(rendered).to have_field('project_disabled_repository_size_limit', disabled: true)
      end
    end

    context 'with a valid license and service ping disabled' do
      before do
        license = build(:license)
        allow(License).to receive(:current).and_return(license)
        stub_application_setting(usage_ping_enabled: false)

        render
      end

      it 'does not render registration features CTA' do
        expect(rendered).not_to have_content(message)
      end
    end
  end
end
