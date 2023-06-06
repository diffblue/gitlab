# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ai::JobFailureAnalysis, :clean_gitlab_redis_cache, feature_category: :continuous_integration do
  let(:job) { create(:ci_build) }
  let(:job2) { create(:ci_build) }
  let(:new_content) { 'new content' }
  let(:new_content2) { 'new content' }

  subject { described_class.new(job) }

  describe '#save_content' do
    it 'sets the content per job' do
      subject.save_content(new_content)

      expect(subject.content).to eq(new_content)

      job_2_analysis = described_class.new(job2)
      job_2_analysis.save_content(new_content2)

      expect(job_2_analysis.content).to eq(new_content2)
    end
  end

  describe 'content' do
    context 'when content is not set' do
      specify { expect(subject.content).to eq(nil) }
    end

    context 'when content is set' do
      before do
        subject.save_content(new_content)
      end

      specify { expect(subject.content).to eq(new_content) }
    end
  end
end
