# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ldap, feature_category: :system_access do
  include ApiHelpers
  include LdapHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:admin) }

  let(:adapter) { ldap_adapter }

  before do
    groups = [
      instance_double(EE::Gitlab::Auth::Ldap::Group, cn: 'developers'),
      instance_double(EE::Gitlab::Auth::Ldap::Group, cn: 'students')
    ]

    allow(Gitlab::Auth::Ldap::Config).to receive(:enabled?).and_return(true)
    allow(Gitlab::Auth::Ldap::Adapter).to receive(:new).and_return(adapter)
    allow(adapter).to receive_messages(groups: groups)
    stub_application_setting(allow_group_owners_to_manage_ldap: false)
  end

  describe "GET /ldap/groups" do
    context "when unauthenticated" do
      it "returns authentication error" do
        get api("/ldap/groups")
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context "when authenticated as user" do
      it "returns authentication error" do
        get api("/ldap/groups", user)
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when group owners are allowed to manage LDAP' do
      before do
        stub_application_setting(allow_group_owners_to_manage_ldap: true)
      end

      it "returns an array of ldap groups" do
        get api("/ldap/groups", user)
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq 2
        expect(json_response.first['cn']).to eq 'developers'
      end
    end

    context "when authenticated as admin" do
      it "returns an array of ldap groups" do
        get api("/ldap/groups", admin)
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq 2
        expect(json_response.first['cn']).to eq 'developers'
      end
    end
  end

  describe "GET /ldap/ldapmain/groups" do
    context "when unauthenticated" do
      it "returns authentication error" do
        get api("/ldap/ldapmain/groups")
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context "when authenticated as user" do
      it "returns authentication error" do
        get api("/ldap/ldapmain/groups", user)
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when group owners are allowed to manage LDAP' do
      before do
        stub_application_setting(allow_group_owners_to_manage_ldap: true)
      end

      it "returns an array of ldap groups" do
        get api("/ldap/ldapmain/groups", admin)
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq 2
        expect(json_response.first['cn']).to eq 'developers'
      end
    end

    context "when authenticated as admin" do
      it "returns an array of ldap groups" do
        get api("/ldap/ldapmain/groups", admin)
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq 2
        expect(json_response.first['cn']).to eq 'developers'
      end
    end
  end
end
