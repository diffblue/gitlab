# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::FreeUserCap do
  using RSpec::Parameterized::TableSyntax

  describe '.enforce_preview_or_standard?' do
    let(:namespace) { build(:namespace) }

    subject { described_class.enforce_preview_or_standard?(namespace) }

    where(:enforce_preview, :enforce_standard, :result) do
      true  | true  | true
      true  | false | true
      false | true  | true
      false | false | false
    end

    before do
      allow_next_instance_of(::Namespaces::FreeUserCap::Preview, namespace) do |instance|
        allow(instance).to receive(:enforce_cap?).and_return(enforce_preview)
      end

      allow_next_instance_of(::Namespaces::FreeUserCap::Standard, namespace) do |instance|
        allow(instance).to receive(:enforce_cap?).and_return(enforce_standard)
      end
    end

    with_them do
      it { is_expected.to be result }
    end
  end

  describe '.dashboard_limit' do
    subject { described_class.dashboard_limit }

    context 'when set to default' do
      it { is_expected.to eq 0 }
    end

    context 'when not set to default' do
      before do
        stub_ee_application_setting(dashboard_limit: 5)
      end

      it { is_expected.to eq 5 }
    end
  end
end
