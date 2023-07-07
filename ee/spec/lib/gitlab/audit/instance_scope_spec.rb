# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Audit::InstanceScope, feature_category: :audit_events do
  describe '#initialize' do
    it 'sets correct attributes' do
      expect(described_class.new)
        .to have_attributes(id: 1, name: Gitlab::Audit::InstanceScope::SCOPE_NAME,
          full_path: Gitlab::Audit::InstanceScope::SCOPE_NAME)
    end

    describe '#licensed_feature_available?' do
      subject { described_class.new.licensed_feature_available?(:external_audit_events) }

      context 'when license is available' do
        before do
          stub_licensed_features(external_audit_events: true)
        end

        it { is_expected.to be_truthy }
      end

      context 'when license is not available' do
        it { is_expected.to be_falsey }
      end
    end
  end
end
