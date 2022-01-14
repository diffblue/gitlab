# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DastSiteProfilesFinder do
  let!(:current_user) { create(:user) }
  let!(:dast_site_profile1) { create(:dast_site_profile) }
  let!(:project1) { dast_site_profile1.project }
  let!(:dast_site_profile2) { create(:dast_site_profile) }
  let!(:project2) { dast_site_profile2.project }
  let!(:dast_site_profile3) { create(:dast_site_profile, project: project1) }

  let(:params) { {} }

  subject do
    described_class.new(params).execute
  end

  describe '#execute' do
    it 'returns all dast_site_profiles' do
      expect(subject).to contain_exactly(dast_site_profile1, dast_site_profile2, dast_site_profile3)
    end

    it 'eager loads the dast_site association' do
      dast_site_profile1 = subject.first!

      recorder = ActiveRecord::QueryRecorder.new do
        dast_site_profile1.dast_site
      end

      expect(recorder.count).to be_zero
    end

    it 'eager loads the dast_site_validation association' do
      dast_site_profile1 = subject.first!

      recorder = ActiveRecord::QueryRecorder.new do
        dast_site_profile1.dast_site_validation
      end

      expect(recorder.count).to be_zero
    end

    context 'filtering by id' do
      let(:params) { { id: dast_site_profile1.id } }

      it 'returns a single dast_site_profile' do
        expect(subject).to contain_exactly(dast_site_profile1)
      end
    end

    context 'filtering by name' do
      let(:params) { { name: dast_site_profile1.name } }

      it 'returns a single dast_site_profile' do
        expect(subject).to contain_exactly(dast_site_profile1)
      end
    end

    context 'filtering by names' do
      let(:params) { { name: [dast_site_profile1.name, dast_site_profile2.name] } }

      it 'returns a single dast_site_profile' do
        expect(subject).to contain_exactly(dast_site_profile1, dast_site_profile2)
      end
    end

    context 'when the dast_site_profile1 does not exist' do
      let(:params) { { id: 0 } }

      it 'returns an empty relation' do
        expect(subject).to be_empty
      end
    end
  end
end
