# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Saml::Config do
  describe '.group_sync_enabled?' do
    subject { described_class.group_sync_enabled? }

    it { is_expected.to eq(false) }

    context 'when SAML is enabled' do
      before do
        allow(described_class).to receive_messages({ options: { name: 'saml', args: {} } })
        allow(Gitlab::Auth::OAuth::Provider).to receive(:providers).and_return([:saml])
      end

      it { is_expected.to eq(false) }

      context 'when the group attribute is configured' do
        before do
          allow(described_class).to receive(:groups).and_return(['Groups'])
        end

        it { is_expected.to eq(false) }

        context 'when the saml_group_sync feature is licensed' do
          before do
            stub_licensed_features(saml_group_sync: true)
          end

          it { is_expected.to eq(true) }
        end
      end
    end
  end
end
