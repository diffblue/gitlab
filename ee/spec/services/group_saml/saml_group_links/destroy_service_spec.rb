# frozen_string_literal: true

require "spec_helper"

RSpec.describe GroupSaml::SamlGroupLinks::DestroyService, feature_category: :system_access do
  subject(:service) { described_class.new(current_user: current_user, group: group, saml_group_link: saml_group_link) }

  let_it_be(:group) { create(:group) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:saml_group_link) { create(:saml_group_link, group: group) }

  describe "#execute" do
    let(:params) do
      { id: saml_group_link.id }
    end

    let_it_be(:audit_event_message) { "SAML group links removed. Group Name - #{saml_group_link.saml_group_name}" }

    context "when authorized user" do
      before_all do
        group.add_owner(current_user)
      end
      let_it_be(:saml_provider) { create(:saml_provider, group: group, enabled: true) }

      context "when licensed feature is available" do
        before do
          stub_licensed_features(group_saml: true, saml_group_sync: true)
        end

        it "create a new saml_group_link entry against the group" do
          audit_context = {
            name: 'saml_group_links_removed',
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
