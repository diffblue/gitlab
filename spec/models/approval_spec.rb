# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Approval, feature_category: :code_review_workflow do
  let_it_be(:example_value) { "example" }

  context 'presence validation' do
    it { is_expected.to validate_presence_of(:merge_request_id) }
    it { is_expected.to validate_presence_of(:user_id) }
  end

  context 'uniqueness validation' do
    let!(:existing_record) { create(:approval) }

    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to([:merge_request_id]) }
  end

  def fetch_from_cache(key)
    Gitlab::Redis::SharedState.with { |redis| redis.get(key) }
  end

  describe "caching of approved SHAs", :clean_gitlab_redis_shared_state do
    let(:approval) { create(:approval) }

    it "sets the cache to merge_request.diff_head_sha on create" do
      expect(approval.approved_sha).to eq(approval.merge_request.diff_head_sha)
    end

    it "removes the cached SHA when the approval is destroyed" do
      cache_key = approval.approved_sha_cache_key

      approval.destroy!

      expect(fetch_from_cache(cache_key)).to be_nil
    end
  end

  describe ".approved_shas_for" do
    let_it_be(:merge_request) { create(:merge_request) }
    let_it_be(:user) { create(:user) }
    let_it_be(:user_2) { create(:user) }
    let_it_be(:approval) { create(:approval, merge_request: merge_request, user: user) }
    let_it_be(:approval_2) { create(:approval, merge_request: merge_request, user: user_2) }

    it "returns an array of unique SHAs for a collection of approvals" do
      expect(approval.approved_sha).to eq(approval_2.approved_sha)

      result = described_class.approved_shas_for([approval, approval_2])

      expect(result.class).to eq(Array)
      expect(result.length).to eq(1)
      expect(result.first).to eq(approval.approved_sha)
      expect(result.first).to eq(approval_2.approved_sha)
    end

    it "returns an empty array when approved_sha_cache_key are nil or missing" do
      expect(approval).to receive(:approved_sha_cache_key).and_return(nil)

      expect(described_class.approved_shas_for([approval])).to eq([])
    end

    context "when merge_request.diff_head_sha is recorded as nil" do
      let_it_be(:merge_request_nil_sha) { create(:merge_request) }

      it "returns an empty array when redis returns empty data" do
        expect(merge_request_nil_sha).to receive(:diff_head_sha).and_return(nil)

        approval_missing_sha = create(:approval, merge_request: merge_request_nil_sha, user: user)

        expect(approval_missing_sha.approved_sha).to eq("")
        expect(described_class.approved_shas_for([approval_missing_sha])).to eq([])
      end
    end
  end
end
