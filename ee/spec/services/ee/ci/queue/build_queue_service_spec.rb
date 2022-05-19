# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Queue::BuildQueueService do
  let_it_be(:project) { create :project, :in_subgroup }

  describe '#traversal_ids_enabled?' do
    subject { described_class.new(nil).traversal_ids_enabled? }

    it { is_expected.to eq true }

    context 'when traversal_ids_for_quota_calculation is disabled' do
      before do
        stub_feature_flags(traversal_ids_for_quota_calculation: false)
      end

      it { is_expected.to eq false }
    end
  end
end
