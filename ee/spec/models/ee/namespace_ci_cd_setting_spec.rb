# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NamespaceCiCdSetting do
  describe '.allowing_stale_runner_pruning', :saas do
    let_it_be(:namespace1) { create(:namespace) }
    let_it_be(:namespace2) { create(:namespace) }

    subject { described_class.allowing_stale_runner_pruning }

    context 'when there are no runner settings' do
      it { is_expected.to be_empty }
    end

    context 'when there are CI/CD settings' do
      let!(:ci_cd_settings1) do
        ::NamespaceCiCdSetting.find_or_initialize_by(
          namespace_id: namespace1.id,
          allow_stale_runner_pruning: allow_stale_runner_pruning
        ).tap(&:save!)
      end

      context 'allowing stale runner pruning' do
        let(:allow_stale_runner_pruning) { true }

        it { is_expected.to match_array(ci_cd_settings1) }
      end

      context 'not allowing stale runner pruning' do
        let(:allow_stale_runner_pruning) { false }

        it { is_expected.to be_empty }
      end
    end
  end
end
