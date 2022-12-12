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
  end
end
