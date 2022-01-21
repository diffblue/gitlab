# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dast::ProfilesPipeline, type: :model do
  subject { create(:dast_profiles_pipeline) }

  describe 'associations' do
    it { is_expected.to belong_to(:ci_pipeline).class_name('Ci::Pipeline').required }
    it { is_expected.to belong_to(:dast_profile).class_name('Dast::Profile').required }
  end

  context 'loose foreign key on dast_profiles_pipelines.ci_pipeline_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:ci_pipeline) }
      let!(:model) { create(:dast_profiles_pipeline, ci_pipeline: parent) }
    end
  end
end
