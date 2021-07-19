# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::LicensesController do
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'Upload license' do
    render_views

    it 'redirects back when no license is entered/uploaded' do
      expect do
        post :create, params: { license: { data: '' } }
      end.not_to change(License, :count)

      expect(response).to redirect_to new_admin_license_path
      expect(flash[:alert]).to include 'Please enter or upload a valid license.'
    end

    context 'when the license is for a cloud license' do
      it 'redirects back' do
        license = build_license(cloud_licensing_enabled: true)

        expect do
          post :create, params: { license: { data: license.data } }
        end.not_to change(License, :count)

        expect(response).to redirect_to new_admin_license_path
        expect(flash[:alert]).to include 'Please enter or upload a valid license.'
      end
    end

    it 'renders new with an alert when an invalid license is entered/uploaded' do
      expect do
        post :create, params: { license: { data: 'GA!89-)GaRBAGE' } }
      end.not_to change(License, :count)

      expect(response).to render_template(:new)
      expect(response.body).to include('The license key is invalid. Make sure it is exactly as you received it from GitLab Inc.')
    end

    it 'redirects to the subscription page when a valid license is entered/uploaded' do
      license = build_license

      expect do
        post :create, params: { license: { data: license.data } }
      end.to change(License, :count).by(1)

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
        end.to change(License, :count).by(1)

        expect(response).to redirect_to(admin_subscription_path)
      end
    end

    def build_license(cloud_licensing_enabled: false, restrictions: {})
      license_restrictions = {
        trial: false,
        plan: License::PREMIUM_PLAN,
        active_user_count: 1,
        previous_user_count: 1
      }.merge(restrictions)

      gl_license = build(
        :gitlab_license,
        cloud_licensing_enabled: cloud_licensing_enabled,
        restrictions: license_restrictions
      )

      build(:license, data: gl_license.export)
    end
  end

  describe 'POST sync_seat_link' do
    let_it_be(:historical_data) { create(:historical_data, recorded_at: Time.current) }

    before do
      allow(License).to receive(:current).and_return(create(:license, cloud: cloud_license_enabled ))
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

    context 'with a cloud license' do
      let(:is_cloud_license) { true }

      it 'is can not be removed' do
        delete :destroy

        expect(response).to redirect_to(admin_subscription_path)
        expect(flash[:error]).to match('Cloud licenses can not be removed.')
        expect(cloud_licenses).to be_present
      end
    end

    context 'with a legacy license' do
      let(:is_cloud_license) { false }

      it 'is can be removed' do
        delete :destroy

        expect(response).to redirect_to(admin_subscription_path)
        expect(flash[:notice]).to match('The license was removed. GitLab has fallen back on the previous license.')
        expect(cloud_licenses).to be_empty
      end
    end
  end
end
