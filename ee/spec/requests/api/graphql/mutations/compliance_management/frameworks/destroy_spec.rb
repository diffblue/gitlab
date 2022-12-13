# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Delete a compliance framework', feature_category: :compliance_management do
  include GraphqlHelpers

  let_it_be(:namespace) { create(:group) }
  let_it_be(:framework) { create(:compliance_framework, namespace: namespace) }

  let(:current_user) { create(:user) }
  let(:mutation) { graphql_mutation(:destroy_compliance_framework, { id: global_id_of(framework) }) }

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  def mutation_response
    graphql_mutation_response(:destroy_compliance_framework)
  end

  context 'feature is unlicensed' do
    before do
      stub_licensed_features(custom_compliance_frameworks: false)
    end

    it 'does not destroy a compliance framework' do
      expect { subject }.not_to change { ComplianceManagement::Framework.count }
    end

    it_behaves_like 'a mutation that returns top-level errors',
                    errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
  end

  context 'when licensed' do
    before do
      stub_licensed_features(custom_compliance_frameworks: true)
    end

    context 'current_user is namespace owner' do
      before do
        namespace.add_owner(current_user)
      end

      it 'has no errors' do
        subject

        expect(mutation_response['errors']).to be_empty
      end

      it 'destroys a compliance framework' do
        expect { subject }.to change { ComplianceManagement::Framework.count }.by(-1)
      end
    end

    context 'current_user is not namespace owner' do
      it_behaves_like 'a mutation that returns top-level errors',
                      errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]

      it 'does not destroy a compliance framework' do
        expect { subject }.not_to change { ComplianceManagement::Framework.count }
      end
    end
  end
end
