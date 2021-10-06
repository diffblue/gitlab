# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create an external audit event destination' do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:owner) { create(:user) }

  let(:current_user) { owner }

  let(:input) do
    {
      'groupPath': group.full_path,
      'destinationUrl': 'https://gitlab.com/example/testendpoint'
    }
  end

  let(:mutation) { graphql_mutation(:external_audit_event_destination_create, input) }

  let(:mutation_response) { graphql_mutation_response(:external_audit_event_destination_create) }

  shared_examples 'a mutation that does not create a destination' do
    it 'does not destroy the destination' do
      expect { post_graphql_mutation(mutation, current_user: owner) }
        .not_to change { AuditEvents::ExternalAuditEventDestination.count }
    end
  end

  context 'when feature is licensed' do
    before do
      stub_licensed_features(external_audit_events: true)
    end

    context 'when current user is a group owner' do
      before do
        group.add_owner(owner)
      end

      it 'creates the destination' do
        expect { post_graphql_mutation(mutation, current_user: owner) }
          .to change { AuditEvents::ExternalAuditEventDestination.count }.by(1)
      end
    end

    context 'when current user is a group owner' do
      before do
        group.add_owner(owner)
      end

      it 'creates the destination' do
        expect { post_graphql_mutation(mutation, current_user: owner) }
          .to change { AuditEvents::ExternalAuditEventDestination.count }.by(1)
      end
    end

    context 'when current user is a group maintainer' do
      before do
        group.add_maintainer(owner)
      end

      it_behaves_like 'a mutation that does not create a destination'
    end

    context 'when current user is a group developer' do
      before do
        group.add_developer(owner)
      end

      it_behaves_like 'a mutation that does not create a destination'
    end

    context 'when current user is a group guest' do
      before do
        group.add_guest(owner)
      end

      it_behaves_like 'a mutation that does not create a destination'
    end

    context 'when feature is disabled' do
      before do
        stub_feature_flags(ff_external_audit_events_namespace: false)
      end

      it_behaves_like 'a mutation on an unauthorized resource'

      it 'does not create the destination' do
        expect { post_graphql_mutation(mutation, current_user: owner) }
          .not_to change { AuditEvents::ExternalAuditEventDestination.count }
      end
    end
  end

  context 'when feature is unlicensed' do
    before do
      stub_licensed_features(external_audit_events: false)
    end

    it_behaves_like 'a mutation on an unauthorized resource'

    it 'does not create the destination' do
      expect { post_graphql_mutation(mutation, current_user: owner) }
        .not_to change { AuditEvents::ExternalAuditEventDestination.count }
    end
  end
end
