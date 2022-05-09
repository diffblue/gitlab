# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DastScannerProfilesFinder do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:dast_scanner_profile1) { create(:dast_scanner_profile) }
  let_it_be(:dast_scanner_profile2) { create(:dast_scanner_profile) }
  let_it_be(:dast_scanner_profile3) { create(:dast_scanner_profile) }

  let(:params) { {} }

  subject do
    described_class.new(params).execute
  end

  describe '#execute' do
    it 'returns all dast_scanner_profiles' do
      expect(subject).to contain_exactly(dast_scanner_profile1, dast_scanner_profile2, dast_scanner_profile3)
    end

    context 'filtering by ids' do
      let(:params) { { ids: [dast_scanner_profile1.id, dast_scanner_profile3.id] } }

      it 'returns the dast_scanner_profile' do
        expect(subject).to contain_exactly(dast_scanner_profile1, dast_scanner_profile3)
      end
    end

    context 'filter by projects' do
      let(:params) { { project_ids: [dast_scanner_profile1.project.id, dast_scanner_profile2.project.id] } }

      it 'returns the matching dast_scanner_profiles' do
        expect(subject).to contain_exactly(dast_scanner_profile1, dast_scanner_profile2)
      end
    end

    context 'filter by a project' do
      let(:params) { { project_id: dast_scanner_profile1.project.id } }

      it 'returns the matching dast_scanner_profile' do
        expect(subject).to contain_exactly(dast_scanner_profile1)
      end
    end

    context 'filter by name' do
      let(:params) { { name: dast_scanner_profile1.name } }

      it 'returns the matching dast_scanner_profiles' do
        expect(subject).to contain_exactly(dast_scanner_profile1)
      end
    end

    context 'filter by names' do
      let(:params) { { name: [dast_scanner_profile1.name, dast_scanner_profile2.name] } }

      it 'returns the matching dast_scanner_profiles' do
        expect(subject).to contain_exactly(dast_scanner_profile1, dast_scanner_profile2)
      end
    end

    context 'when DastScannerProfile id is for a different project' do
      let(:params) { { ids: [dast_scanner_profile1.id], project_ids: [dast_scanner_profile2.project.id] } }

      it 'returns an empty relation' do
        expect(subject).to be_empty
      end
    end

    context 'when the dast_scanner_profile1 does not exist' do
      let(:params) { { ids: [0] } }

      it 'returns an empty relation' do
        expect(subject).to be_empty
      end
    end
  end
end
