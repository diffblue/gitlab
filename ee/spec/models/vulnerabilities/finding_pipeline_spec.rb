# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::FindingPipeline, feature_category: :vulnerability_management do
  describe 'associations' do
    it { is_expected.to belong_to(:pipeline).class_name('Ci::Pipeline') }
    it { is_expected.to belong_to(:finding).class_name('Vulnerabilities::Finding') }
  end

  describe 'validations' do
    let!(:finding_pipeline) { create(:vulnerabilities_finding_pipeline) }

    it { is_expected.to validate_presence_of(:finding) }
    it { is_expected.to validate_presence_of(:pipeline) }
    it { is_expected.to validate_uniqueness_of(:pipeline_id).scoped_to(:occurrence_id) }
  end

  context 'loose foreign key on vulnerability_occurrence_pipelines.pipeline_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:ci_pipeline) }
      let!(:model) { create(:vulnerabilities_finding_pipeline, pipeline: parent) }
    end
  end
end
