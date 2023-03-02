# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComplianceManagement::Frameworks::UpdateService, feature_category: :compliance_management do
  let_it_be_with_refind(:namespace) { create(:group) }
  let_it_be_with_refind(:framework) { create(:compliance_framework, namespace: namespace) }
  let_it_be(:current_user) { create(:user) }

  before do
    namespace.add_owner(current_user)
  end

  let(:params) { { color: '#000001', description: 'New Description', name: 'New Name' } }

  subject { described_class.new(framework: framework, current_user: current_user, params: params) }

  shared_examples 'a failed update request' do
    it 'does not update the compliance framework' do
      expect { subject.execute }.not_to change { framework.name }
      expect { subject.execute }.not_to change { framework.description }
      expect { subject.execute }.not_to change { framework.color }
    end

    it 'is unsuccessful' do
      expect(subject.execute.success?).to be false
    end
  end

  context 'feature is unlicensed' do
    before do
      stub_licensed_features(custom_compliance_frameworks: false)
    end

    it_behaves_like 'a failed update request'
  end

  context 'current_user is not the namespace owner' do
    let(:current_user) { create(:user) }

    it_behaves_like 'a failed update request'
  end

  context 'when feature is licensed' do
    before do
      stub_licensed_features(custom_compliance_frameworks: true)
    end

    context 'with an invalid param passed' do
      let(:params) { { color: '0001', description: '', name: 'New Name' } }

      it 'is unsuccessful' do
        expect(subject.execute.success?).to be false
      end

      it 'has appropriate errors' do
        expect(subject.execute.payload.full_messages).to contain_exactly 'Color must be a valid color code', "Description can't be blank"
      end
    end

    context 'with valid params passed' do
      it 'updates the compliance framework with valid params' do
        subject.execute

        expect(framework.name).to eq('New Name')
        expect(framework.color).to eq('#000001')
        expect(framework.description).to eq('New Description')
      end

      it 'is successful' do
        expect(subject.execute.success?).to be true
      end

      it 'audits the changes' do
        expect { subject.execute }.to change { AuditEvent.count }.by(3)

        messages = AuditEvent.last(3).map { |e| e.details[:custom_message] }

        expect(messages).to contain_exactly(
          'Changed compliance framework\'s name from GDPR to New Name',
          'Changed compliance framework\'s color from #004494 to #000001',
          'Changed compliance framework\'s description from The General Data Protection Regulation (GDPR) is a regulation in EU law on data protection and privacy in the European Union (EU) and the European Economic Area (EEA). to New Description'
        )
      end

      context 'when default param is used' do
        context 'when true' do
          before do
            params[:default] = true
            namespace.namespace_settings.update!(default_compliance_framework_id: nil)
          end

          it 'updates the default compliance framework for the namespace' do
            expect_next_instance_of(::Groups::UpdateService) do |group_update_service|
              expect(group_update_service).to receive(:execute).and_call_original
            end

            subject.execute

            expect(namespace.reload.namespace_settings.default_compliance_framework_id).to eq(framework.id)
          end
        end

        context 'when false' do
          before do
            params[:default] = false
          end

          it 'does not update the default framework for the namespace when default framework is not set' do
            namespace.namespace_settings.update!(default_compliance_framework_id: nil)

            expect(::Groups::UpdateService).not_to receive(:new)

            subject.execute

            expect(namespace.reload.namespace_settings.default_compliance_framework_id).to be_nil
          end

          it 'removes the default framework for the namespace' do
            namespace.namespace_settings.update!(default_compliance_framework_id: framework.id)

            expect_next_instance_of(::Groups::UpdateService) do |group_update_service|
              expect(group_update_service).to receive(:execute).and_call_original
            end

            subject.execute

            expect(namespace.reload.namespace_settings.default_compliance_framework_id).to be_nil
          end
        end
      end
    end
  end
end
