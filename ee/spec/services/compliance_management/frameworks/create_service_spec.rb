# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComplianceManagement::Frameworks::CreateService do
  let_it_be_with_refind(:namespace) { create(:user_namespace) }

  let(:params) do
    {
      name: 'GDPR',
      description: 'The EUs data protection directive',
      color: '#abc123'
    }
  end

  context 'custom_compliance_frameworks is disabled' do
    before do
      stub_licensed_features(custom_compliance_frameworks: false)
    end

    subject { described_class.new(namespace: namespace, params: params, current_user: namespace.owner) }

    it 'does not create a new compliance framework' do
      expect { subject.execute }.not_to change { ComplianceManagement::Framework.count }
    end

    it 'responds with an error message' do
      expect(subject.execute.message).to eq('Not permitted to create framework')
    end
  end

  context 'custom_compliance_frameworks is enabled' do
    before do
      stub_licensed_features(custom_compliance_frameworks: true)
    end

    context 'namespace has a parent' do
      let_it_be(:user) { create(:user) }
      let_it_be_with_reload(:group) { create(:group, :with_hierarchy) }

      let(:descendant) { group.descendants.first }

      before do
        group.add_owner(user)
      end

      subject { described_class.new(namespace: descendant, params: params, current_user: user) }

      it 'responds with a successful service response' do
        expect(subject.execute.success?).to be true
      end

      it 'creates the new framework in the root namespace' do
        expect(subject.execute.payload[:framework].namespace).to eq(group)
      end
    end

    context 'when using invalid parameters' do
      subject { described_class.new(namespace: namespace, params: params.except(:name), current_user: namespace.owner) }

      let(:response) { subject.execute }

      it 'responds with an error service response' do
        expect(response.success?).to eq false
        expect(response.payload.messages[:name]).to contain_exactly "can't be blank"
      end
    end

    context 'when creating a compliance framework for a namespace that current_user is not the owner of' do
      subject { described_class.new(namespace: namespace, params: params, current_user: create(:user)) }

      it 'responds with an error service response' do
        expect(subject.execute.success?).to be false
      end

      it 'does not create a new compliance framework' do
        expect { subject.execute }.not_to change { ComplianceManagement::Framework.count }
      end
    end

    context 'when pipeline_configuration_full_path parameter is used and feature is not available' do
      subject { described_class.new(namespace: namespace, params: params, current_user: namespace.owner) }

      before do
        params[:pipeline_configuration_full_path] = '.compliance-gitlab-ci.yml@compliance/hipaa'
        stub_licensed_features(custom_compliance_frameworks: true, evaluate_group_level_compliance_pipeline: false)
      end

      let(:response) { subject.execute }

      it 'returns an error', :aggregate_failures do
        expect(response.success?).to be false
        expect(response.message).to eq 'Pipeline configuration full path feature is not available'
      end
    end

    context 'when using parameters for a valid compliance framework' do
      subject { described_class.new(namespace: namespace, params: params, current_user: namespace.owner) }

      it 'audits the changes' do
        expect { subject.execute }.to change { AuditEvent.count }.by(1)
      end

      it 'creates a new compliance framework' do
        expect { subject.execute }.to change { ComplianceManagement::Framework.count }.by(1)
      end

      it 'responds with a successful service response' do
        expect(subject.execute.success?).to be true
      end

      it 'has the expected attributes' do
        framework = subject.execute.payload[:framework]

        expect(framework.name).to eq('GDPR')
        expect(framework.description).to eq('The EUs data protection directive')
        expect(framework.color).to eq('#abc123')
      end

      context 'when compliance pipeline configuration is available' do
        before do
          params[:pipeline_configuration_full_path] = '.compliance-gitlab-ci.yml@compliance/hipaa'
          stub_licensed_features(custom_compliance_frameworks: true, evaluate_group_level_compliance_pipeline: true)
        end

        it 'sets the pipeline configuration path attribute' do
          framework = subject.execute.payload[:framework]

          expect(framework.pipeline_configuration_full_path).to eq('.compliance-gitlab-ci.yml@compliance/hipaa')
        end
      end
    end
  end
end
