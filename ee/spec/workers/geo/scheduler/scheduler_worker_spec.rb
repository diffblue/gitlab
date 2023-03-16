# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::Scheduler::SchedulerWorker, :geo, feature_category: :geo_replication do
  subject { described_class.new }

  it 'includes ::Gitlab::Geo::LogHelpers' do
    expect(described_class).to include_module(::Gitlab::Geo::LogHelpers)
  end

  it 'needs many other specs'

  describe '#take_batch' do
    let(:a) { [[2, :lfs], [3, :lfs]] }
    let(:b) { [] }
    let(:c) { [[3, :job_artifact], [8, :job_artifact], [9, :job_artifact]] }

    context 'without batch_size' do
      it 'returns a batch of jobs' do
        expect(subject).to receive(:db_retrieve_batch_size).and_return(4)

        expect(subject.send(:take_batch, a, b, c)).to eq(
          [
            [2, :lfs],
            [3, :job_artifact],
            [3, :lfs],
            [8, :job_artifact]
          ])
      end
    end

    context 'with batch_size' do
      it 'returns a batch of jobs' do
        expect(subject.send(:take_batch, a, b, c, batch_size: 2)).to eq(
          [
            [2, :lfs],
            [3, :job_artifact]
          ])
      end
    end
  end
end
