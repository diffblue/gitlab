# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pagination::Keyset::SimpleOrderBuilder do
  context 'when ordering by a CASE expression and id' do
    let(:scope) { Vulnerability.order(Vulnerability.report_type_order.asc) }

    subject(:result) { described_class.build(scope) }

    it 'does not raise error' do
      expect { result }.not_to raise_error
    end

    it 'does not support this ordering' do
      _, success = result

      expect(success).to eq(false)
    end
  end
end
