# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineEntity, feature_category: :continuous_integration do
  let(:user) { build_stubbed(:user) }
  let(:pipeline) { build_stubbed(:ci_empty_pipeline) }
  let(:request) { double('request', current_user: user) }
  let(:entity) { described_class.represent(pipeline, request: request) }

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains flags' do
      expect(subject).to include :flags
      expect(subject[:flags]).to include :merge_train_pipeline
    end
  end
end
