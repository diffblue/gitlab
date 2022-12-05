# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::LicensesController, feature_category: :sm_provisioning do
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'Upload license' do
    render_views

    it 'redirects back when no license is entered/uploaded' do
      expect do
        post :create, params: { license: { data: '' } }
      end.not_to change { License.count }

      expect(response).to redirect_to general_admin_application_settings_path
      expect(flash[:alert]).to include(
        'The license you uploaded is invalid. If the issue persists, contact support at ' \
          '<a href="https://support.gitlab.com">https://support.gitlab.com</a>'
      )
    end

    context 'when the license is for a cloud license' do
      context 'with offline cloud license' do
        it 'redirects to the subscription page when a valid license is entered/uploaded' do
          license = build_license(cloud_licensing_enabled: true, offline_cloud_licensing_enabled: true)

          expect do
            post :create, params: { license: { data: license.data } }
          end.to change { License.count }.by(1)

          expect(response).to redirect_to(admin_subscription_path)
        end
      end

      context 'with online cloud license' do
        it 'redirects back' do
          license = build_license(cloud_licensing_enabled: true)

          expect do
            post :create, params: { license: { data: license.data } }
          end.not_to change { License.count }

          expect(response).to redirect_to general_admin_application_settings_path
          expect(flash[:alert]).to include(
            html_escape("It looks like you're attempting to activate your subscription. Use %{link} instead.") % {
              link: "<a href=\"#{admin_subscription_path}\">the Subscription page</a>".html_safe
            }
          )
        end
      end
    end

    it 'renders new with an alert when an invalid license is entered/uploaded' do
      expect do
        post :create, params: { license: { data: 'GA!89-)GaRBAGE' } }
      end.not_to change { License.count }

      expect(response).to redirect_to general_admin_application_settings_path
      expect(flash[:alert]).to include(_('The license key is invalid. Make sure it is exactly as you received it from GitLab Inc.'))
    end

    it 'redirects to the subscription page when a valid license is entered/uploaded' do
      license = build_license

      expect do
        post :create, params: { license: { data: license.data } }
      end.to change { License.count }.by(1)

      expect(response).to redirect_to(admin_subscription_path)
    end

    context 'Trials' do
      before do
        stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
      end

      it 'redirects to the subscription page when a valid trial license is entered/uploaded' do
        license = build_license(restrictions: { trial: true })

        expect do
          post :create, params: { license: { data: license.data } }
        end.to change { License.count }.by(1)

        expect(response).to redirect_to(admin_subscription_path)
      end
    end

    def build_license(cloud_licensing_enabled: false, offline_cloud_licensing_enabled: false, restrictions: {})
      license_restrictions = {
        trial: false,
        plan: License::PREMIUM_PLAN,
        active_user_count: 1,
        previous_user_count: 1
      }.merge(restrictions)

      gl_license = build(
        :gitlab_license,
        cloud_licensing_enabled: cloud_licensing_enabled,
        offline_cloud_licensing_enabled: offline_cloud_licensing_enabled,
        restrictions: license_restrictions
      )

      build(:license, data: gl_license.export)
    end
  end

  describe 'POST sync_seat_link' do
    let_it_be(:historical_data) { create(:historical_data, recorded_at: Time.current) }

    before do
      allow(License).to receive(:current).and_return(create(:license, cloud: cloud_license_enabled))
    end

    context 'with a cloud license' do
      let(:cloud_license_enabled) { true }

      it 'returns a success response' do
        post :sync_seat_link, format: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ 'success' => true })
      end
    end

    context 'without a cloud license' do
      let(:cloud_license_enabled) { false }

      it 'returns a failure response' do
        post :sync_seat_link, format: :json

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response).to eq({ 'success' => false })
      end
    end
  end

  describe 'DELETE destroy' do
    let(:cloud_licenses) { License.where(cloud: true) }

    before do
      allow(License).to receive(:current).and_return(create(:license, cloud: is_cloud_license))
    end

    shared_examples 'license removal' do
      it 'removes the license' do
        delete :destroy, format: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ 'success' => true })
        expect(flash[:notice]).to match('The license was removed. GitLab has fallen back on the previous license.')
        expect(cloud_licenses).to be_empty
      end
    end

    context 'with a cloud license' do
      let(:is_cloud_license) { true }

      it_behaves_like 'license removal'
    end

    context 'with a legacy license' do
      let(:is_cloud_license) { false }

      it_behaves_like 'license removal'
    end
  end
end
