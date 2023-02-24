# frozen_string_literal: true

require "spec_helper"

RSpec.describe API::SamlGroupLinks, api: true, feature_category: :system_access do
  include ApiHelpers

  let_it_be(:owner) { create(:user) }
  let_it_be(:user) { create(:user) }
  let(:current_user) { nil }

  let_it_be(:group_with_saml_group_links) do
    group = create(:group)
    group.saml_group_links.create!(saml_group_name: "saml-group1", access_level: ::Gitlab::Access::GUEST)
    group.saml_group_links.create!(saml_group_name: "saml-group2", access_level: ::Gitlab::Access::GUEST)
    group.saml_group_links.create!(saml_group_name: "saml-group3", access_level: ::Gitlab::Access::GUEST)
    group
  end

  let_it_be(:saml_provider) { create(:saml_provider, group: group_with_saml_group_links, enabled: true) }
  let_it_be(:group_id) { group_with_saml_group_links.id }

  before do
    group_with_saml_group_links.add_owner owner
    group_with_saml_group_links.add_member user, Gitlab::Access::DEVELOPER
  end

  shared_examples 'has expected results' do
    it "returns SAML group links" do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to(
        match([
                { "access_level" => ::Gitlab::Access::GUEST, "name" => "saml-group1" },
                { "access_level" => ::Gitlab::Access::GUEST, "name" => "saml-group2" },
                { "access_level" => ::Gitlab::Access::GUEST, "name" => "saml-group3" }
              ])
      )
    end
  end

  describe "GET /groups/:id/saml_group_links" do
    subject { get api("/groups/#{group_id}/saml_group_links", current_user) }

    context "when license feature is available" do
      before do
        stub_licensed_features(group_saml: true, saml_group_sync: true)
      end

      context "when unauthorized" do
        it "returns unauthorized error" do
          subject

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context "when a less privileged user" do
        let(:current_user) { user }

        it "returns unauthorized error" do
          subject

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context "when owner of the group" do
        let(:current_user) { owner }

        it_behaves_like 'has expected results'

        context "when group does not have any associated saml_group_links" do
          let_it_be(:group_with_no_saml_links) { create(:group) }
          let_it_be(:saml_provider) { create(:saml_provider, group: group_with_no_saml_links, enabled: true) }
          let_it_be(:group_id) { group_with_no_saml_links.id }

          before do
            group_with_no_saml_links.add_owner owner
          end

          it "returns empty array as response" do
            subject

            aggregate_failures "testing response" do
              expect(response).to have_gitlab_http_status(:ok)
              expect(json_response).to(match([]))
            end
          end
        end

        context 'with URL-encoded path of the group' do
          let(:group_id) { group_with_saml_group_links.full_path }

          it_behaves_like 'has expected results'
        end
      end
    end

    context "when license feature is not available" do
      let(:current_user) { owner }

      it "returns unauthorized error" do
        subject

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe "POST /groups/:id/saml_group_links" do
    let_it_be(:params) { { saml_group_name: "Test group", access_level: ::Gitlab::Access::GUEST } }

    subject { post api("/groups/#{group_id}/saml_group_links", current_user), params: params }

    context "when licensed feature is available" do
      before do
        stub_licensed_features(group_saml: true, saml_group_sync: true)
      end

      context "when unauthorized" do
        it "returns unauthorized error" do
          subject

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context "when a less privileged user" do
        let(:current_user) { user }

        it "does not allow less privileged user to add SAML group link" do
          expect do
            subject
          end.not_to change { group_with_saml_group_links.saml_group_links.count }

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context "when owner of the group and group is saml enabled" do
        let(:current_user) { owner }

        it "returns ok and add saml group link" do
          expect do
            subject
          end.to change { group_with_saml_group_links.saml_group_links.count }.by(1)

          aggregate_failures "testing response" do
            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['name']).to eq('Test group')
            expect(json_response['access_level']).to eq(::Gitlab::Access::GUEST)
          end
        end

        context "when params are missing" do
          let(:params) { { saml_group_name: "Test group" } }

          it "returns a 400 error when params are missing" do
            subject

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end

        context "when params are invalid" do
          let(:params) { { saml_group_name: "Test group", access_level: 11 } }

          it "returns a 400 error when params are invalid" do
            subject

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end
    end

    context "when licensed feature is not available" do
      let(:current_user) { owner }

      it "returns unauthorized error" do
        subject

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe "GET /groups/:id/saml_group_links/:saml_group_name" do
    let_it_be(:saml_group_name) { "saml-group1" }

    subject { get api("/groups/#{group_id}/saml_group_links/#{saml_group_name}", current_user) }

    context "when licensed feature is available" do
      before do
        stub_licensed_features(group_saml: true, saml_group_sync: true)
      end

      context "when unauthorized" do
        it "returns unauthorized error" do
          subject

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context "when owner of the group" do
        let(:current_user) { owner }

        it "gets saml group link" do
          subject

          aggregate_failures "testing response" do
            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['name']).to eq('saml-group1')
            expect(json_response['access_level']).to eq(::Gitlab::Access::GUEST)
          end
        end

        context "when invalid group name is passed" do
          let(:saml_group_name) { "saml-group1356" }

          it "returns 404 if SAML group can not used for a SAML group link" do
            subject

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end

    context "when licensed feature is not available" do
      let(:current_user) { owner }

      it "returns authentication error" do
        subject

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE /groups/:id/saml_group_links/:saml_group_name" do
    let_it_be(:saml_group_name) { "saml-group1" }

    subject { delete api("/groups/#{group_id}/saml_group_links/#{saml_group_name}", current_user) }

    context "when licensed feature is available" do
      before do
        stub_licensed_features(group_saml: true, saml_group_sync: true)
      end

      context "when unauthorized" do
        it "returns unauthorized error" do
          subject

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context "when a less privileged user" do
        let(:current_user) { user }

        it "does not remove the SAML group link" do
          expect do
            subject
          end.not_to change { group_with_saml_group_links.saml_group_links.count }

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context "when owner of the group" do
        let(:current_user) { owner }

        it "removes saml group link" do
          expect do
            subject

            expect(response).to have_gitlab_http_status(:no_content)
          end.to change { group_with_saml_group_links.saml_group_links.count }.by(-1)
        end

        context "when invalid group name is passed" do
          let(:saml_group_name) { "saml-group1356" }

          it "returns 404 if SAML group can not used for a SAML group link" do
            expect do
              subject
            end.not_to change { group_with_saml_group_links.saml_group_links.count }

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end

    context "when licensed feature is not available" do
      let(:current_user) { owner }

      it "returns authentication error" do
        subject

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end
