# frozen_string_literal: true

require "spec_helper"

RSpec.describe API::ProviderIdentity, api: true, feature_category: :system_access do
  include ApiHelpers

  let_it_be(:owner) { create(:user) }
  let_it_be(:guest_user_1) { create(:user) }
  let_it_be(:guest_user_2) { create(:user) }
  let(:current_user) { nil }

  let_it_be(:group) do
    group = create(:group)
    group.add_guest(guest_user_1)
    group.add_guest(guest_user_2)
    group.add_owner(owner)
    group
  end

  let_it_be(:saml_provider) { create(:saml_provider, group: group) }

  let_it_be(:saml_identity_one) do
    create(:identity, user_id: guest_user_1.id, provider: 'group_saml',
                      saml_provider_id: saml_provider.id, extern_uid: 'saml-uid-1')
  end

  let_it_be(:saml_identity_two) do
    create(:identity, user_id: owner.id, provider: 'group_saml',
                      saml_provider_id: saml_provider.id, extern_uid: 'saml-uid-2')
  end

  let_it_be(:scim_identity_one) do
    create(:scim_identity, user: guest_user_1, group: group, extern_uid: 'scim-uid-1')
  end

  let_it_be(:scim_identity_two) do
    create(:scim_identity, user: owner, group: group, extern_uid: 'scim-uid-2')
  end

  let_it_be(:saml_identity_with_dot) do
    create(:identity, user_id: guest_user_2.id, provider: 'group_saml',
                      saml_provider_id: saml_provider.id, extern_uid: 'saml-test@gmail.com')
  end

  let_it_be(:scim_identity_with_dot) do
    create(:scim_identity, user: guest_user_2, group: group, extern_uid: 'scim-test@gmail.com')
  end

  describe "Provider Identity API" do
    using RSpec::Parameterized::TableSyntax

    where(:provider_type, :provider_extern_uid_1, :provider_extern_uid_2, :provider_extern_uid_with_dot, :identity_type,
:validation_error) do
      "saml" | "saml-uid-1" | "saml-uid-2" | "saml-test@gmail.com" | Identity | "SAML NameID can't be blank"
      "scim" | "scim-uid-1" | "scim-uid-2" | "scim-test@gmail.com" | ScimIdentity | "Extern uid can't be blank"
    end

    with_them do
      context "when GET identities" do
        subject(:get_identities) { get api("/groups/#{group.id}/#{provider_type}/identities", current_user) }

        context "when user is not a group owner" do
          let(:current_user) { guest_user_1 }

          it "throws unauthorized error" do
            get_identities

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context "when user is group owner" do
          let(:current_user) { owner }

          it "returns the list of identities" do
            get_identities

            if identity_type == ScimIdentity
              expect(json_response).to(
                match_array(
                  [
                    { "extern_uid" => provider_extern_uid_1, "user_id" => guest_user_1.id, "active" => true },
                    { "extern_uid" => provider_extern_uid_2, "user_id" => owner.id, "active" => true },
                    { "extern_uid" => provider_extern_uid_with_dot, "user_id" => guest_user_2.id, "active" => true }
                  ]
                )
              )
            else
              expect(json_response).to(
                match_array(
                  [
                    { "extern_uid" => provider_extern_uid_1, "user_id" => guest_user_1.id },
                    { "extern_uid" => provider_extern_uid_2, "user_id" => owner.id },
                    { "extern_uid" => provider_extern_uid_with_dot, "user_id" => guest_user_2.id }
                  ]
                )
              )
            end
          end
        end
      end

      context "when PATCH uid" do
        subject(:patch_identities) do
          patch api("/groups/#{group.id}/#{provider_type}/#{uid}", current_user),
          params: { extern_uid: extern_uid }
        end

        context "when user is not a group owner" do
          let(:uid) { provider_extern_uid_1 }
          let(:current_user) { guest_user_1 }
          let(:extern_uid) { 'updated_uid' }

          it "throws forbidden error" do
            patch_identities

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context "when user is a group owner" do
          let(:current_user) { owner }
          let(:extern_uid) { "updated_uid" }

          context "when invalid uid is passed" do
            let(:uid) { "test_uid" }

            it "returns not found error" do
              patch_identities

              expect(response).to have_gitlab_http_status(:not_found)
            end
          end

          context "when valid uid is passed" do
            let(:uid) { provider_extern_uid_1 }

            it "updates the identity record with extern_uid passed" do
              patch_identities

              expect(response).to have_gitlab_http_status(:ok)

              # Check that response is equal to the updated object
              expect(json_response['extern_uid']).to eq('updated_uid')
            end

            context "when extern uid contains period" do
              let(:uid) { provider_extern_uid_with_dot }
              let(:extern_uid) { 'updated_test@gmail.com' }

              it "updates the identity record" do
                patch api("/groups/#{group.id}/#{provider_type}/#{uid}", current_user),
                params: { extern_uid: extern_uid }

                expect(response).to have_gitlab_http_status(:ok)

                # Check that response is equal to the updated object
                expect(json_response['extern_uid']).to eq('updated_test@gmail.com')
              end
            end

            context "when invalid extern_uid to update is passed" do
              let(:uid) { provider_extern_uid_1 }
              let(:extern_uid) { "" }

              it "throws bad request error" do
                patch_identities

                expect(response).to have_gitlab_http_status(:bad_request)
                expect(json_response['message']).to eq(validation_error)
              end
            end
          end

          context "when params contain attribute other than extern_uid" do
            it "does not update any other param" do
              expect do
                patch api("/groups/#{group.id}/#{provider_type}/#{scim_identity_one.extern_uid}", current_user),
                params: { active: false }

                expect(json_response['error']).to eq("extern_uid is missing")
              end.not_to change(scim_identity_one, :active)
            end

            it "throws error when param is missing" do
              patch api("/groups/#{group.id}/#{provider_type}/#{provider_extern_uid_1}", current_user)

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end
        end
      end
    end
  end
end
