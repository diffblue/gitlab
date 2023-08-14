# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo::BatchCounter, :geo, feature_category: :geo_replication do
  let(:subject_class) do
    Class.new do
      include Gitlab::Geo::BatchCounter
    end
  end

  subject(:batch_counter) { subject_class.new }

  describe '#batch_count' do
    let(:model) { Issue }
    let(:column) { :id }

    before do
      allow(model.connection).to receive(:transaction_open?).and_return(false)
    end

    it 'passes 100_000 to max_allowed_loops' do
      expect_next_instance_of(::Gitlab::Database::BatchCounter, model,
        column: column, max_allowed_loops: 100_000) do |instance|
        expect(instance).to receive(:count).once
      end

      batch_counter.batch_count(model, column)
    end

    it "does not return fallback if loops are more than Gitlab::Database::BatchCounter::MAX_ALLOWED_LOOPS" do
      stub_const('Gitlab::Database::BatchCounter::MAX_ALLOWED_LOOPS', 0)

      expect(batch_counter.batch_count(model, column)).not_to eq(::Gitlab::Database::BatchCounter::FALLBACK)
    end
  end
end
