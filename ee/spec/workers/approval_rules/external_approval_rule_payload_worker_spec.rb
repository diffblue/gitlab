# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApprovalRules::ExternalApprovalRulePayloadWorker, feature_category: :source_code_management do
  let_it_be(:rule) { create(:external_status_check, external_url: 'https://example.com/callback') }

  subject { described_class.new.perform(rule.id, {}) }

  describe "#perform" do
    before do
      stub_outbound_request
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [rule.id, {}] }
    end

    it 'executes a WebHookService' do
      expect(subject.success?).to be true
    end
  end

  private

  def stub_outbound_request
    stub_request(:post, "https://example.com/callback").to_return(status: 200, body: "", headers: {})
  end
end
