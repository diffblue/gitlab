# frozen_string_literal: true

RSpec.shared_examples_for 'has secrets' do |ci_type|
  subject(:ci) { build(ci_type) }

  describe 'delegations' do
    it { is_expected.to delegate_method(:secrets).to(:metadata).allow_nil }
  end

  describe '#secrets?' do
    subject { ci.secrets? }

    context 'without metadata' do
      let(:ci) { build(ci_type) }

      it { is_expected.to be(false) }
    end

    context 'with metadata' do
      let(:ci) { build(ci_type, metadata: build(:ci_build_metadata, secrets: secrets)) }

      context 'when secrets exist' do
        let(:secrets) { { PASSWORD: { vault: {} } } }

        it { is_expected.to be(true) }
      end

      context 'when secrets do not exit' do
        let(:secrets) { nil }

        it { is_expected.to be(false) }
      end
    end
  end
end
