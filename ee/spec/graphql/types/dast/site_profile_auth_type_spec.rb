# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DastSiteProfileAuth'] do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, developer_projects: [project]) }
  let_it_be(:object, reload: true) { create(:dast_site_profile, project: project) }
  let_it_be(:fields) { %i[enabled url usernameField passwordField username password submitField] }

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  specify { expect(described_class.graphql_name).to eq('DastSiteProfileAuth') }
  specify { expect(described_class).to require_graphql_authorizations(:read_on_demand_dast_scan) }

  it { expect(described_class).to have_graphql_fields(fields) }

  describe 'enabled field' do
    it 'is auth_enabled' do
      expect(resolve_field(:enabled, object, current_user: user)).to eq(object.auth_enabled)
    end
  end

  describe 'url field' do
    it 'is auth_url' do
      expect(resolve_field(:url, object, current_user: user)).to eq(object.auth_url)
    end
  end

  describe 'usernameField field' do
    it 'is auth_username_field' do
      expect(resolve_field(:username_field, object, current_user: user)).to eq(object.auth_username_field)
    end
  end

  describe 'passwordField field' do
    it 'is auth_password_field' do
      expect(resolve_field(:password_field, object, current_user: user)).to eq(object.auth_password_field)
    end
  end

  describe 'submitField field' do
    it 'is auth_submit_field' do
      expect(resolve_field(:submit_field, object, current_user: user)).to eq(object.auth_submit_field)
    end
  end

  describe 'username field' do
    it 'is auth_username' do
      expect(resolve_field(:username, object, current_user: user)).to eq(object.auth_username)
    end
  end

  describe 'password field' do
    context 'when there is no associated secret variable' do
      it 'is nil' do
        expect(resolve_field(:password, object, current_user: user)).to be_nil
      end
    end

    context 'when there an associated secret variable' do
      it 'is redacted' do
        create(:dast_site_profile_secret_variable, :password, dast_site_profile: object)

        expect(resolve_field(:password, object, current_user: user)).to eq('••••••••')
      end
    end
  end
end
