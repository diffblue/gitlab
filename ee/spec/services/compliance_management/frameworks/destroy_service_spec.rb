# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComplianceManagement::Frameworks::DestroyService, feature_category: :compliance_management do
  let_it_be_with_refind(:namespace) { create(:group) }
  let_it_be_with_refind(:framework) { create(:compliance_framework, namespace: namespace) }
  let_it_be(:user) { create(:user) }

  before do
    namespace.add_owner(user)
  end

  context 'when feature is disabled' do
    before do
      stub_licensed_features(custom_compliance_frameworks: false)
    end

    subject { described_class.new(framework: framework, current_user: user) }

    it 'does not destroy the compliance framework' do
      expect { subject.execute }.not_to change { ComplianceManagement::Framework.count }
    end

    it 'is unsuccessful' do
      expect(subject.execute.success?).to be false
    end
  end

  context 'when feature is enabled' do
    before do
      stub_licensed_features(custom_compliance_frameworks: true)
    end

    context 'when current user is namespace owner' do
      subject { described_class.new(framework: framework, current_user: user) }

      it 'destroys the compliance framework' do
        expect { subject.execute }.to change { ComplianceManagement::Framework.count }.by(-1)
      end

      it 'is successful' do
        expect(subject.execute.success?).to be true
      end

      it 'audits the destruction' do
        expect { subject.execute }.to change { AuditEvent.count }.by(1)
      end

      it 'does not destroy the default compliance framework' do
        namespace.namespace_settings.update!(default_compliance_framework_id: framework.id)

        response = subject.execute

        expect(response.success?).to be false
        expect(response.errors).to match_array(["Cannot delete the default framework"])
      end
    end

    context 'when current user is not the namespace owner' do
      subject { described_class.new(framework: framework, current_user: create(:user)) }

      it 'does not destroy the compliance framework' do
        expect { subject.execute }.not_to change { ComplianceManagement::Framework.count }
      end

      it 'is unsuccessful' do
        expect(subject.execute.success?).to be false
      end
    end
  end
end
