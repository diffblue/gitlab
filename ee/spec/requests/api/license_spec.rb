# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::License, api: true, feature_category: :sm_provisioning do
  include ApiHelpers

  let(:gl_license)  { build(:gitlab_license) }
  let(:license)     { build(:license, data: gl_license.export) }
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }

  def license_json(license)
    {
      id: license.id,
      plan: license.plan,
      created_at: license.created_at.iso8601(3),
      starts_at: license.starts_at.to_date.to_s,
      expires_at: license.expires_at.to_date.to_s,
      historical_max: license.historical_max,
      licensee: license.licensee,
      add_ons: license.add_ons,
      expired: license.expired?,
      overage: license.overage,
      user_limit: license.restricted_user_count,
      maximum_user_count: license.maximum_user_count
    }
  end

  describe 'GET /license' do
    it 'retrieves the license information if admin is logged in' do
      get api('/license', admin)
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['user_limit']).to eq 0
      expect(Date.parse(json_response['starts_at'])).to eq Date.new(1970, 1, 1)
      expect(Date.parse(json_response['expires_at'])).to eq Date.today + 11.months
      expect(json_response['active_users']).to eq 1
      expect(json_response['licensee']).not_to be_empty
      expect(json_response['add_ons']).to eq(license.add_ons)
    end

    it 'denies access if not admin' do
      get api('/license', user)
      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  describe 'POST /license' do
    it 'adds a new license if admin is logged in' do
      post api('/license', admin), params: { license: gl_license.export }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['user_limit']).to eq 0
      expect(Date.parse(json_response['starts_at'])).to eq Date.new(1970, 1, 1)
      expect(Date.parse(json_response['expires_at'])).to eq Date.today + 11.months
      expect(json_response['active_users']).to eq 1
      expect(json_response['licensee']).not_to be_empty
    end

    it 'denies access if not admin' do
      post api('/license', user), params: { license: license }

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'returns 400 if the license cannot be saved' do
      post api('/license', admin), params: { license: 'foo' }

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  describe 'DELETE /license/:id' do
    let(:cloud_licensing_enabled) { false }
    let(:license) do
      gitlab_license = build(
        :gitlab_license,
        cloud_licensing_enabled: cloud_licensing_enabled,
        starts_at: Date.current,
        expires_at: Date.current,
        restrictions: { add_ons: { 'GitLab_DeployBoard' => 1 }, active_user_count: 2 }
      )

      create(:license, created_at: Time.now, data: gitlab_license.export)
    end

    let(:endpoint) { "/license/#{license.id}" }

    shared_examples 'license removal' do
      it 'destroys a license and returns 204' do
        delete api(endpoint, admin)

        expect(response).to have_gitlab_http_status(:no_content)
        expect(response.message).to eq('No Content')
        expect(License.where(id: license.id)).not_to exist
      end
    end

    it_behaves_like 'license removal'

    it "returns an error if the license doesn't exist" do
      delete api("/license/0", admin)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Not found')
    end

    it 'returns 403 if the user is not an admin' do
      delete api(endpoint, user)

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(json_response['message']).to eq('403 Forbidden')
    end

    context 'with a cloud license' do
      let(:cloud_licensing_enabled) { true }

      it_behaves_like 'license removal'
    end
  end

  describe 'GET /license/:id', :aggregate_failures do
    let(:license) { create(:license) }
    let(:endpoint) { "/license/#{license.id}" }

    it 'gets a license by its id' do
      get api(endpoint, admin)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['id']).to eq(license.id)
      expect(json_response['active_users']).to eq(1)
    end

    it "returns an error if the license doesn't exist" do
      get api("/license/#{non_existing_record_id}", admin)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Not Found')
    end

    it 'returns 403 if the user is not an admin' do
      get api(endpoint, user)

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(json_response['message']).to eq('403 Forbidden')
    end
  end

  describe 'GET /licenses' do
    let(:endpoint) { '/licenses' }
    let(:gl_licenses) do
      [build(:gitlab_license, starts_at: Date.today - 10, expires_at: Date.today - 1, restrictions: { add_ons: { 'GitLab_FileLocks' => 1 }, active_user_count: 10 }),
       build(:gitlab_license, starts_at: Date.today - 20, expires_at: Date.today + 1, restrictions: { add_ons: { 'GitLab_DeployBoard' => 1 }, active_user_count: 20 })]
    end

    let!(:licenses) do
      [create(:license, created_at: Time.now + 30, data: gl_licenses[0].export),
       create(:license, created_at: Time.now + 20, data: gl_licenses[1].export)]
    end

    it 'returns a collection of licenses' do
      get api(endpoint, admin)

      expect(response).to have_gitlab_http_status(:ok)

      2.times do
        expect(json_response.shift.symbolize_keys).to contain_exactly(*license_json(licenses.pop))
      end
    end

    it 'returns an empty array if no licenses exist' do
      License.delete_all

      get api(endpoint, admin)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq([])
    end

    it 'returns 403 if the user is not an admin' do
      get api(endpoint, user)

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(json_response['message']).to eq('403 Forbidden')
    end
  end
end
