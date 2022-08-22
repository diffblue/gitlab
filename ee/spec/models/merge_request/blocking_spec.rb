# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequest do
  let(:block) { create(:merge_request_block) }

  let(:blocking_mr) { block.blocking_merge_request }
  let(:blocked_mr) { block.blocked_merge_request }

  describe 'associations' do
    it { expect(blocking_mr.blocks_as_blocker).to contain_exactly(block) }
    it { expect(blocking_mr.blocks_as_blockee).to be_empty }

    it { expect(blocked_mr.blocks_as_blocker).to be_empty }
    it { expect(blocked_mr.blocks_as_blockee).to contain_exactly(block) }

    it { expect(blocking_mr.blocking_merge_requests).to be_empty }
    it { expect(blocking_mr.blocked_merge_requests).to contain_exactly(blocked_mr) }

    it { expect(blocked_mr.blocking_merge_requests).to contain_exactly(blocking_mr) }
    it { expect(blocked_mr.blocked_merge_requests).to be_empty }
  end

  describe '#merge_blocked_by_other_mrs?' do
    context 'licensed' do
      before do
        stub_licensed_features(blocking_merge_requests: true)
      end

      it 'is false for the blocking MR' do
        expect(blocking_mr.merge_blocked_by_other_mrs?).to be(false)
      end

      it 'is true for the blocked MR when the blocking MR is open' do
        expect(blocked_mr.merge_blocked_by_other_mrs?).to be(true)
      end

      it 'is true for the blocked MR when the blocking MR is closed' do
        blocking_mr.close!

        expect(blocked_mr.merge_blocked_by_other_mrs?).to be(true)
      end

      it 'is false for the blocked MR when the blocking MR is merged' do
        blocking_mr.state = 'merged'
        blocking_mr.save!(validate: false)

        expect(blocked_mr.merge_blocked_by_other_mrs?).to be(false)
      end
    end

    context 'unlicensed' do
      before do
        stub_licensed_features(blocking_merge_requests: false)
      end

      it 'is false for the blocked MR' do
        expect(blocked_mr.merge_blocked_by_other_mrs?).to be(false)
      end
    end
  end

  describe '#visible_blocking_merge_requests' do
    let(:block) { create(:merge_request_block) }
    let(:blocking_mr) { block.blocking_merge_request }
    let(:blocked_mr) { block.blocked_merge_request }
    let(:user) { create(:user) }

    it 'shows blocking MR to developer' do
      blocking_mr.target_project.team.add_developer(user)

      expect(blocked_mr.visible_blocking_merge_requests(user)).to contain_exactly(blocking_mr)
    end

    it 'hides block from guest' do
      blocking_mr.target_project.team.add_guest(user)

      expect(blocked_mr.visible_blocking_merge_requests(user)).to be_empty
    end

    it 'hides block from anonymous user' do
      expect(blocked_mr.visible_blocking_merge_requests(nil)).to be_empty
    end
  end

  describe '#visible_blocking_merge_request_refs' do
    let(:merge_request) { create(:merge_request) }
    let(:other_mr) { create(:merge_request) }
    let(:user) { create(:user) }

    it 'returns the references for the result of #visible_blocking_merge_requests' do
      expect(merge_request)
        .to receive(:visible_blocking_merge_requests)
        .with(user)
        .and_return([other_mr])

      expect(merge_request.visible_blocking_merge_request_refs(user))
        .to eq([other_mr.to_reference(full: true)])
    end
  end

  describe '#hidden_blocking_merge_requests_count' do
    let(:block) { create(:merge_request_block) }
    let(:blocking_mr) { block.blocking_merge_request }
    let(:blocked_mr) { block.blocked_merge_request }
    let(:user) { create(:user) }

    it 'returns 0 when all MRs are visible' do
      blocking_mr.target_project.team.add_developer(user)

      expect(blocked_mr.hidden_blocking_merge_requests_count(user)).to eq(0)
    end

    context 'MR is hidden' do
      before do
        blocking_mr.target_project.team.add_guest(user)
      end

      it 'returns 1 when MR is unmerged by default' do
        expect(blocked_mr.hidden_blocking_merge_requests_count(user)).to eq(1)
      end

      context 'MR is merged' do
        before do
          blocking_mr.update_columns(state_id: described_class.available_states[:merged])
        end

        it 'returns 0 by default' do
          expect(blocked_mr.hidden_blocking_merge_requests_count(user)).to eq(0)
        end

        it 'returns 1 when include_merged: true' do
          expect(blocked_mr.hidden_blocking_merge_requests_count(user, include_merged: true)).to eq(1)
        end
      end
    end
  end
end
