# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::ComplianceManagement::Frameworks::Destroy do
  include GraphqlHelpers

  let_it_be(:namespace) { create(:group) }
  let_it_be(:framework) { create(:compliance_framework, namespace: namespace) }

  let(:user) { create(:user) }
  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  subject { mutation.resolve(id: global_id_of(framework)) }

  before do
    namespace.add_owner(user)
  end

  shared_examples 'a compliance framework that cannot be found' do
    it 'raises an error' do
      expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end
  end

  shared_examples 'one compliance framework was destroyed' do
    it 'destroys a compliance framework' do
      expect { subject }.to change { ComplianceManagement::Framework.count }.by(-1)
    end

    it 'expects zero errors in the response' do
      expect(subject[:errors]).to be_empty
    end
  end

  context 'feature is unlicensed' do
    before do
      stub_licensed_features(custom_compliance_frameworks: false)
    end

    it_behaves_like 'a compliance framework that cannot be found'
  end

  context 'feature is licensed' do
    before do
      stub_licensed_features(custom_compliance_frameworks: true)
    end

    context 'current_user is namespace owner' do
      it_behaves_like 'one compliance framework was destroyed'
    end

    context 'current_user is group owner' do
      let_it_be(:group) { create(:group) }
      let_it_be(:user) { create(:user) }
      let_it_be(:framework) { create(:compliance_framework, namespace: group) }

      before do
        group.add_owner(user)
      end

      it_behaves_like 'one compliance framework was destroyed'
    end
  end
end
