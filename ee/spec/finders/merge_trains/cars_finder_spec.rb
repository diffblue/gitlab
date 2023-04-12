# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeTrains::CarsFinder, feature_category: :merge_trains do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:guest) { create(:user) }

  let(:finder) { described_class.new(project, user, params) }
  let(:user) { developer }
  let(:params) { {} }

  before_all do
    project.add_developer(developer)
    project.add_guest(guest)
  end

  describe '#execute' do
    subject { finder.execute }

    let!(:train_car_1) { create(:merge_train_car, target_project: project, target_branch: 'main') }
    let!(:train_car_2) { create(:merge_train_car, target_project: project, target_branch: 'main') }

    it 'returns merge trains ordered by id' do
      is_expected.to eq([train_car_1, train_car_2])
    end

    context 'when sort is asc' do
      let(:params) { { sort: 'asc' } }

      it 'returns merge trains in ascending order' do
        is_expected.to eq([train_car_1, train_car_2])
      end
    end

    context 'when sort is desc' do
      let(:params) { { sort: 'desc' } }

      it 'returns merge trains in descending order' do
        is_expected.to eq([train_car_2, train_car_1])
      end
    end

    context 'when user is a guest' do
      let(:user) { guest }

      it 'returns an empty list' do
        is_expected.to be_empty
      end
    end

    context 'when scope is given' do
      let!(:train_car_1) { create(:merge_train_car, :idle, target_project: project) }
      let!(:train_car_2) { create(:merge_train_car, :merged, target_project: project) }

      context 'when scope is active' do
        let(:params) { { scope: 'active' } }

        it 'returns active merge train' do
          is_expected.to eq([train_car_1])
        end
      end

      context 'when scope is complete' do
        let(:params) { { scope: 'complete' } }

        it 'returns complete merge train' do
          is_expected.to eq([train_car_2])
        end
      end
    end

    context 'when target branch is given' do
      let(:params) { { target_branch: 'main' } }

      it 'returns merge train for target branch' do
        is_expected.to match_array([train_car_1, train_car_2])
      end

      context 'with multiple merge trains for project' do
        let!(:train_car_3) { create(:merge_train_car, target_project: project, target_branch: 'develop') }

        it 'returns merge train for target branch' do
          is_expected.to match_array([train_car_1, train_car_2])
        end
      end
    end

    context 'when target branch has empty merge_train' do
      let(:params) { { target_branch: 'random' } }

      it 'returns an empty list' do
        is_expected.to be_empty
      end
    end
  end
end
