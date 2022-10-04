# frozen_string_literal: true

require "spec_helper"

RSpec.describe API::MemberRoles, api: true do
  include ApiHelpers

  let_it_be(:owner) { create(:user) }
  let_it_be(:user) { create(:user) }
  let(:current_user) { nil }

  let_it_be(:group_with_member_roles) do
    group = create(:group)
    group.add_owner(owner)
    group
  end

  let_it_be(:child_group) { create :group, parent: group_with_member_roles }

  let_it_be(:member_role_1) do
    create(:member_role, namespace: group_with_member_roles,
                         base_access_level: ::Gitlab::Access::REPORTER,
                         download_code: 0)
  end

  let_it_be(:member_role_2) do
    create(:member_role, namespace: group_with_member_roles,
                         base_access_level: ::Gitlab::Access::REPORTER,
                         download_code: 1)
  end

  let_it_be(:group_id) { group_with_member_roles.id }

  describe "GET /groups/:id/member_roles" do
    subject { get api("/groups/#{group_id}/member_roles", current_user) }

    context "when unauthorized" do
      it "returns forbidden error" do
        subject

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context "when a less privileged user" do
      let(:current_user) { user }

      it "returns forbidden error" do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context "when owner of the group" do
      let(:current_user) { owner }

      it "returns associated member roles" do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to(
          match([
                  {
                    "id" => member_role_1.id,
                    "base_access_level" => ::Gitlab::Access::REPORTER,
                    "download_code" => false,
                    "group_id" => group_id
                  },
                  {
                    "id" => member_role_2.id,
                    "base_access_level" => ::Gitlab::Access::REPORTER,
                    "download_code" => true,
                    "group_id" => group_id
                  }
                ])
        )
      end

      context "when group does not have any associated member_roles" do
        let_it_be(:group_with_no_member_roles) { create(:group) }
        let_it_be(:group_id) { group_with_no_member_roles.id }

        before do
          group_with_no_member_roles.add_owner owner
        end

        it "returns empty array as response" do
          subject

          aggregate_failures "testing response" do
            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to(match([]))
          end
        end
      end
    end
  end

  describe "POST /groups/:id/member_roles" do
    let_it_be(:params) { { base_access_level: 40, download_code: 1 } }

    subject { post api("/groups/#{group_id}/member_roles", current_user), params: params }

    context "when feature flag is enabled" do
      before do
        stub_feature_flags(customizable_roles: [group_with_member_roles])
      end

      context "when unauthorized" do
        it "returns unauthorized error" do
          subject

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context "when a less privileged user" do
        let(:current_user) { user }

        it "does not allow less privileged user to add member roles" do
          expect do
            subject
          end.not_to change { group_with_member_roles.member_roles.count }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context "when owner of the group" do
        let(:current_user) { owner }

        it "returns ok and add member role" do
          expect do
            subject
          end.to change { group_with_member_roles.member_roles.count }.by(1)

          aggregate_failures "testing response" do
            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['base_access_level']).to eq(::Gitlab::Access::MAINTAINER)
            expect(json_response['download_code']).to eq(true)
          end
        end

        context "when params are missing" do
          let(:params) { { download_code: 0 } }

          it "returns a 400 error when params are missing" do
            subject

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['error']).to match(/base_access_level is missing/)
          end
        end

        context "when params are invalid" do
          let(:params) { { base_access_level: 1, download_code: 1 } }

          it "returns a 400 error when params are invalid" do
            subject

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['error']).to eq('base_access_level does not have a valid value')
          end
        end

        context "when errors during creation of new record" do
          before do
            allow_next_instance_of(MemberRole) do |instance|
              instance.errors.add(:base, 'validation error')

              allow(instance).to receive(:valid?).and_return(false)
            end
          end

          it "returns a error message with 400 code" do
            subject

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to eq('validation error')
          end
        end
      end
    end

    context "when feature flag is disabled" do
      before do
        stub_feature_flags(customizable_roles: false)
      end

      let(:current_user) { owner }

      it "returns unauthorized error" do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe "DELETE /groups/:id/member_roles/:member_role_id" do
    let_it_be(:member_role_id) { member_role_1.id }

    subject { delete api("/groups/#{group_id}/member_roles/#{member_role_id}", current_user) }

    context "when feature flag is enabled" do
      before do
        stub_feature_flags(customizable_roles: [group_with_member_roles])
      end

      context "when unauthorized" do
        it "returns unauthorized error" do
          subject

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context "when a less privileged user" do
        let(:current_user) { user }

        it "does not remove the member role" do
          expect do
            subject
          end.not_to change { group_with_member_roles.member_roles.count }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context "when owner of the group" do
        let(:current_user) { owner }

        it "removes member role" do
          expect do
            subject

            expect(response).to have_gitlab_http_status(:no_content)
          end.to change { group_with_member_roles.member_roles.count }.by(-1)
        end

        context "when invalid group name is passed" do
          let(:member_role_id) { (member_role_1.id + 10) }

          it "returns 404 if SAML group can not used for a SAML group link" do
            expect do
              subject
            end.not_to change { group_with_member_roles.member_roles.count }

            expect(response).to have_gitlab_http_status(:not_found)
            expect(json_response['message']).to eq('Linked Member Role not found')
          end
        end
      end
    end
  end
end
