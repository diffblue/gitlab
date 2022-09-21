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
end
