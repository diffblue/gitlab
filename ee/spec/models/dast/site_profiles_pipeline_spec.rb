# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dast::SiteProfilesPipeline, type: :model do
  subject { create(:dast_site_profiles_pipeline) }

  describe 'associations' do
    it { is_expected.to belong_to(:ci_pipeline).class_name('Ci::Pipeline').required }
    it { is_expected.to belong_to(:dast_site_profile).class_name('DastSiteProfile').required }
  end

  describe 'validations' do
    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:ci_pipeline_id) }
    it { is_expected.to validate_presence_of(:dast_site_profile_id) }

    context 'when the ci_pipeline.project_id and dast_site_profile.project_id do not match' do
      let(:pipeline) { build(:ci_pipeline, project_id: 1) }
      let(:site_profile) { build(:dast_site_profile, project_id: 2) }

      subject { build(:dast_site_profiles_pipeline, ci_pipeline: pipeline, dast_site_profile: site_profile) }

      it 'is not valid', :aggregate_failures do
        expect(subject).not_to be_valid
        expect(subject.errors.full_messages).to include('Ci pipeline project_id must match dast_site_profile.project_id')
      end
    end
  end
end
