# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::PureFindingsFinder, feature_category: :vulnerability_management do
  it_behaves_like 'security findings finder' do
    let(:findings) { finder_result.to_a }
    let(:query_limit) { 8 }

    describe 'parsing artifacts' do
      before do
        allow(::Gitlab::Ci::Parsers).to receive(:fabricate!)
      end

      it 'does not parse artifacts' do
        service_object.execute

        expect(::Gitlab::Ci::Parsers).not_to have_received(:fabricate!)
      end
    end

    describe '#available?' do
      let_it_be(:pipeline) { create(:ci_pipeline) }
      let_it_be(:scan) { create(:security_scan, :latest_successful, pipeline: pipeline) }

      subject { service_object }

      context 'when there are zero security findings' do
        it { is_expected.not_to be_available }
      end

      context 'when there is a security finding without finding data' do
        let_it_be(:security_finding) { create(:security_finding, scan: scan, finding_data: {}) }

        it { is_expected.not_to be_available }
      end

      context 'when there is a security finding with finding data' do
        let_it_be(:security_finding) { create(:security_finding, :with_finding_data, scan: scan) }

        it { is_expected.to be_available }
      end
    end
  end
end
