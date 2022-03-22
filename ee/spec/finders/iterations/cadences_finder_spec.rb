# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Iterations::CadencesFinder do
  let(:params) { {} }

  let_it_be(:group) { create(:group, :private) }
  let_it_be(:sub_group) { create(:group, :private, parent: group) }
  let_it_be(:project) { create(:project, group: sub_group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:active_group_iterations_cadence) { create(:iterations_cadence, group: group, active: true, duration_in_weeks: 1, title: 'one week iterations') }
  let_it_be(:inactive_group_iterations_cadence) { create(:iterations_cadence, group: group, active: false, duration_in_weeks: 2, title: 'two weeks iterations') }
  let_it_be(:automatic_iterations_cadence) { create(:iterations_cadence, group: group, automatic: true, duration_in_weeks: 1, title: 'one week iterations') }
  let_it_be(:active_sub_group_iterations_cadence) { create(:iterations_cadence, group: sub_group, active: true, duration_in_weeks: 1, title: 'one week iterations') }
  let_it_be(:inactive_sub_group_iterations_cadence) { create(:iterations_cadence, group: sub_group, active: false, duration_in_weeks: 2, title: 'two weeks iterations') }
  let_it_be(:non_automatic_sub_group_iterations_cadence) { build(:iterations_cadence, group: sub_group, automatic: false, duration_in_weeks: 1, title: 'one week iterations').tap { |cadence| cadence.save!(validate: false) } }
  let_it_be(:current_group) { group }

  subject { described_class.new(user, current_group, params).execute }

  context 'without permissions' do
    context 'groups and projects' do
      let(:params) { {} }

      it 'returns no iterations cadences for group' do
        expect(subject).to be_empty
      end
    end
  end

  context 'with permissions' do
    before do
      group.add_reporter(user)
    end

    context 'iterations cadences for group' do
      it 'returns iterations cadences' do
        expect(subject).to contain_exactly(
          active_group_iterations_cadence,
          inactive_group_iterations_cadence,
          automatic_iterations_cadence
        )
      end
    end

    context 'iterations cadences for subgroup' do
      let(:current_group) { sub_group }

      it 'returns iterations cadences' do
        expect(subject).to contain_exactly(
          active_sub_group_iterations_cadence,
          inactive_sub_group_iterations_cadence,
          non_automatic_sub_group_iterations_cadence
        )
      end

      context 'with include ancestor' do
        let(:params) { { include_ancestor_groups: true } }

        it 'returns ancestor iterations cadences' do
          expect(subject).to contain_exactly(
            active_group_iterations_cadence,
            inactive_group_iterations_cadence,
            automatic_iterations_cadence,
            active_sub_group_iterations_cadence,
            inactive_sub_group_iterations_cadence,
            non_automatic_sub_group_iterations_cadence
          )
        end
      end
    end

    context 'with filters' do
      let(:current_group) { sub_group }
      let(:params) { { include_ancestor_groups: true } }

      it 'filters by title' do
        params[:title] = 'one week'

        expect(subject).to contain_exactly(
          active_group_iterations_cadence,
          automatic_iterations_cadence,
          active_sub_group_iterations_cadence,
          non_automatic_sub_group_iterations_cadence
        )
      end

      it 'filters by ID' do
        params[:id] = active_sub_group_iterations_cadence.id

        expect(subject).to contain_exactly(active_sub_group_iterations_cadence)
      end

      it 'filters by active true' do
        params[:active] = 'true'

        expect(subject).to contain_exactly(
          active_group_iterations_cadence,
          automatic_iterations_cadence,
          active_sub_group_iterations_cadence,
          non_automatic_sub_group_iterations_cadence
        )
      end

      it 'filters by active false' do
        params[:active] = 'false'

        expect(subject).to contain_exactly(
          inactive_group_iterations_cadence,
          inactive_sub_group_iterations_cadence
        )
      end

      it 'filters by automatic true' do
        params[:automatic] = true

        expect(subject).to contain_exactly(
          active_group_iterations_cadence,
          inactive_group_iterations_cadence,
          automatic_iterations_cadence,
          active_sub_group_iterations_cadence,
          inactive_sub_group_iterations_cadence
        )
      end

      it 'filters by automatic false' do
        params[:automatic] = false

        expect(subject).to contain_exactly(
          non_automatic_sub_group_iterations_cadence
        )
      end

      it 'filters by duration_in_weeks false' do
        params[:duration_in_weeks] = 2

        expect(subject).to contain_exactly(
          inactive_group_iterations_cadence,
          inactive_sub_group_iterations_cadence
        )
      end
    end
  end
end
