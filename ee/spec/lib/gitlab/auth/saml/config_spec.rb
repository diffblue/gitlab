# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Saml::Config, feature_category: :system_access do
  let(:config) { described_class.new }

  def stub_saml_enabled
    allow(config).to receive_messages({ options: { name: 'saml', args: {} } })
    allow(Gitlab::Auth::OAuth::Provider).to receive(:providers).and_return([:saml])
  end

  describe '.group_sync_enabled?' do
    subject { config.group_sync_enabled? }

    it { is_expected.to eq(false) }

    context 'when SAML is enabled' do
      before do
        stub_saml_enabled
      end

      it { is_expected.to eq(false) }

      context 'when the group attribute is configured' do
        before do
          allow(config).to receive(:groups).and_return(['Groups'])
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

  describe '.microsoft_group_sync_enabled?' do
    subject { config.microsoft_group_sync_enabled? }

    using RSpec::Parameterized::TableSyntax

    where(:saml_enabled?, :feature_licensed?, :expect_microsoft_group_sync_enabled?) do
      false | false | false
      true  | false | false
      false | true  | false
      true  | true  | true
    end

    with_them do
      before do
        stub_saml_enabled if saml_enabled?
        stub_licensed_features(microsoft_group_sync: feature_licensed?)
      end

      it { expect(config.microsoft_group_sync_enabled?).to eq(expect_microsoft_group_sync_enabled?) }
    end
  end
end
