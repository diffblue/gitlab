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
      context 'allowing stale runner pruning' do
        before do
          namespace1.update!(allow_stale_runner_pruning: true)
        end

        it { is_expected.to match_array(namespace1.ci_cd_settings) }
      end

      context 'not allowing stale runner pruning' do
        before do
          namespace1.update!(allow_stale_runner_pruning: false)
        end

        it { is_expected.to be_empty }
      end
    end
  end
end
