# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spam::SpamVerdictService, feature_category: :instance_resiliency do
  include_context 'includes Spam constants'

  let_it_be(:user) { build(:user) }
  let_it_be(:project) { build(:project, :public) }
  let_it_be(:issue) { build(:issue, author: user, project: project) }

  let(:service) do
    described_class.new(user: user, target: issue, options: {})
  end

  describe '#execute' do
    subject(:execute) { service.execute }

    before do
      allow(service).to receive(:get_akismet_verdict).and_return(nil)
      allow(service).to receive(:get_spamcheck_verdict).and_return(BLOCK_USER)
    end

    it 'returns a block verdict' do
      is_expected.to eq(BLOCK_USER)
    end

    context 'when user is on a paid plan' do
      before do
        allow(user).to receive(:belongs_to_paid_namespace?).with(exclude_trials: true).and_return(true)
      end

      it 'overrides and renders the override verdict' do
        is_expected.to eq(OVERRIDE_VIA_ALLOW_POSSIBLE_SPAM)
      end
    end
  end
end
