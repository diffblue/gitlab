# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::ComplianceManagement::Frameworks::Update do
  include GraphqlHelpers

  let_it_be(:namespace) { create(:group) }
  let_it_be(:framework) { create(:compliance_framework, namespace: namespace) }

  let(:user) { create(:user) }
  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }
  let(:params) do
    {
      name: 'New Name',
      description: 'New Description',
      color: '#AAAAA1'
    }
  end

  before do
    namespace.add_owner(user)
  end

  subject { mutation.resolve(id: global_id_of(framework), params: params) }

  context 'feature is licensed' do
    before do
      stub_licensed_features(custom_compliance_frameworks: true)
    end

    context 'parameters are valid' do
      it 'returns the new object' do
        response = subject[:compliance_framework]

        expect(response.name).to eq('New Name')
        expect(response.description).to eq('New Description')
        expect(response.color).to eq('#AAAAA1')
      end

      it 'returns no errors' do
        expect(subject[:errors]).to be_empty
      end

      context 'current_user is not authorized to update framework' do
        before do
          namespace.update!(owners: [])
        end

        it 'raises an error' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end
    end

    context 'parameters are invalid' do
      let(:params) do
        {
          name: '',
          description: '',
          color: 'AAAAA1'
        }
      end

      it 'does not change the framework attributes' do
        expect { subject }.not_to change { framework.name }
        expect { subject }.not_to change { framework.description }
        expect { subject }.not_to change { framework.color }
      end

      it 'returns validation errors' do
        expect(subject[:errors]).to contain_exactly("Name can't be blank", "Description can't be blank", "Color must be a valid color code")
      end
    end
  end
end
