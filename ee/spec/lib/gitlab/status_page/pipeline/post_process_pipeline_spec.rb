# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::StatusPage::Pipeline::PostProcessPipeline do
  describe '.filters' do
    subject { described_class.filters }

    it 'has filters in proper position' do
      mention_pos = subject.find_index(Gitlab::StatusPage::Filter::MentionAnonymizationFilter)
      redactor_pos = subject.find_index(::Banzai::Filter::ReferenceRedactorFilter)

      expect(mention_pos).to be < redactor_pos
      expect(subject.last).to eq Gitlab::StatusPage::Filter::ImageFilter
    end

    it { is_expected.to be_frozen }
  end
end
