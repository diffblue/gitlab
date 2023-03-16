# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::VerificationStateBackfillService, :geo, feature_category: :geo_replication do
  let_it_be(:replicable) { create(:merge_request_diff, :external) }

  subject(:job) { described_class.new(MergeRequestDiff, batch_size: 1000) }

  describe '#execute' do
    context 'when a replicable is missing a corresponding verifiable' do
      before do
        replicable.merge_request_diff_detail.destroy!
      end

      it 'adds a new verifiable' do
        expect { job.execute }.to change { MergeRequestDiffDetail.count }.from(0).to(1)
      end
    end

    context 'when some replicables were removed from scope' do
      let(:verifiable) { create(:merge_request_diff_detail, merge_request_diff: replicable) }

      before do
        replicable.update_attribute(:stored_externally, false)
      end

      it 'deletes the verifiable' do
        expect { job.execute }.to change { MergeRequestDiffDetail.count }.from(1).to(0)
      end
    end
  end
end
