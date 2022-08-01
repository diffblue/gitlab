# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dast::ProfilesFinder do
  let_it_be(:project1) { create(:project) }
  let_it_be(:project2) { create(:project) }
  let_it_be(:dast_profile1) { create(:dast_profile, project: project1) }
  let_it_be(:dast_profile2) { create(:dast_profile, project: project2) }
  let_it_be(:dast_profile3) { create(:dast_profile, project: project1) }
  let_it_be(:dast_profile_schedule) { create(:dast_profile_schedule, project: project1, dast_profile: dast_profile3) }

  let(:params) { {} }

  subject do
    described_class.new(params).execute
  end

  describe '#execute' do
    it 'returns dast_profiles limited to 100 records' do
      aggregate_failures do
        expect(Dast::Profile).to receive(:limit).with(100).and_call_original

        expect(subject).to contain_exactly(dast_profile3, dast_profile2, dast_profile1)
      end
    end

    context 'filtering by id' do
      let(:params) { { id: dast_profile1.id } }

      it 'returns the matching dast_profile' do
        expect(subject).to contain_exactly(dast_profile1)
      end
    end

    context 'filtering by project_id' do
      let(:params) { { project_id: project1.id } }

      it 'returns the matching dast_profiles' do
        expect(subject).to contain_exactly(dast_profile3, dast_profile1)
      end
    end

    context 'filtering by has_schedule?' do
      let(:params) { { has_dast_profile_schedule: true } }

      context 'when has_dast_profile_schedule is true' do
        it 'returns the dast_profiles with schedule' do
          expect(subject).to contain_exactly(dast_profile3)
        end
      end
    end

    context 'filtering by *' do
      let(:params) { { id: dast_profile3.id, project_id: project1.id, has_dast_profile_schedule: true } }

      it 'returns the matching dast_profile' do
        expect(subject).to contain_exactly(dast_profile3)
      end
    end

    context 'when the dast_profile does not exist' do
      let(:params) { { project_id: 0 } }

      it 'returns an empty relation' do
        expect(subject).to be_empty
      end
    end

    context 'sorting' do
      it 'orders by id desc by default' do
        expect(subject).to be_sorted(:id, :desc)
      end
    end
  end
end
