# frozen_string_literal: true

require "spec_helper"

RSpec.describe GroupSaml::SamlGroupLinks::CreateService, feature_category: :system_access do
  subject(:service) { described_class.new(current_user: current_user, group: group, params: params) }

  let_it_be(:group) { create(:group) }
  let_it_be(:current_user) { create(:user) }

  describe "#execute" do
    let(:params) do
      {
        saml_group_name: "Test group",
        access_level: ::Gitlab::Access::GUEST
      }
    end

    let_it_be(:audit_event_message) { "SAML group links created. Group Name - Test group, Access Level - 10" }

    context "when authorized user" do
      before do
        group.add_owner(current_user)
      end

      context "when licensed features are available" do
        before do
          stub_licensed_features(group_saml: true, saml_group_sync: true)
        end

        context "with valid params" do
          let_it_be(:saml_provider) { create(:saml_provider, group: group, enabled: true) }

          it "create a new saml_group_link entry against the group" do
            audit_context = {
              name: 'saml_group_links_created',
              author: current_user,
              scope: group,
              target: group,
              message: audit_event_message
            }
            expect(::Gitlab::Audit::Auditor).to receive(:audit).with(audit_context).once.and_call_original

            response = service.execute

            expect(response).to be_success
            expect(AuditEvent.count).to eq(1)
            expect(AuditEvent.last.details[:custom_message]).to eq(audit_event_message)
          end
        end

        context "when invalid params" do
          let(:invalid_params) do
            {
              saml_group_name: "Test group",
              access_level: "invalid"
            }
          end

          subject(:service) { described_class.new(current_user: current_user, group: group, params: invalid_params) }

          it "throws bad request error" do
            response = service.execute
            expect(response).not_to be_success
            expect(response[:error]).to match /Access level is invalid/
          end
        end
      end
    end

    context "when user is not allowed to create saml_group_links" do
      before do
        allow(Ability).to receive(:allowed?).with(current_user, :admin_saml_group_links, group).and_return(false)
      end

      it "throws unauthorized error" do
        response = service.execute

        expect(response).not_to be_success
        expect(response[:message]).to eq("Unauthorized")
      end
    end
  end
end
