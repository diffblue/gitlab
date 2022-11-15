# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::Geo::SettingsController, :geo, feature_category: :geo_replication do
  include EE::GeoHelpers
  include StubENV

  let_it_be(:admin) { create(:admin) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
  end

  shared_examples 'license required' do
    context 'without a valid license' do
      it 'redirects to 403 page' do
        expect(subject).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe '#show' do
    before do
      sign_in(admin)
    end

    context 'without a valid license' do
      subject { get :show }

      render_views

      before do
        stub_licensed_features(geo: false)
      end

      it 'does not redirects to the 403 page' do
        expect(subject).not_to redirect_to(:forbidden)
      end

      it 'does show license alert' do
        expect(subject).to render_template(partial: '_license_alert')
        expect(subject.body).to include('Geo is only available for users who have at least a Premium subscription.')
      end
    end

    context 'with a valid license' do
      subject { get :show }

      render_views

      before do
        stub_licensed_features(geo: true)
      end

      it 'does not show license alert' do
        expect(subject).to render_template(partial: '_license_alert')
        expect(subject.body).not_to include('Geo is only available for users who have at least a Premium subscription.')
      end
    end
  end

  describe '#update' do
    before do
      sign_in(admin)
    end

    String test_value = '1.0.0.0/0, ::/0'

    context 'with a valid license' do
      before do
        stub_licensed_features(geo: true)
        @request.env['HTTP_REFERER'] = admin_geo_settings_path
        patch :update, params: { application_setting: { geo_node_allowed_ips: test_value } }
      end

      it 'sets the geo node property in ApplicationSetting' do
        expect(ApplicationSetting.current.geo_node_allowed_ips).to eq(test_value)
      end

      it 'redirects the update to the referer' do
        expect(request).to redirect_to(admin_geo_settings_path)
      end
    end
  end
end
