import * as actions from 'ee/analytics/cycle_analytics/store/actions/filters';
import * as types from 'ee/analytics/cycle_analytics/store/mutation_types';
import testAction from 'helpers/vuex_action_helper';
import {
  createdAfter,
  createdBefore,
  selectedProjects,
} from 'jest/analytics/cycle_analytics/mock_data';
import { allowedStages as stages } from '../../mock_data';

stages[0].hidden = true;
const activeStages = stages.filter(({ hidden }) => !hidden);

const [selectedStage] = activeStages;

describe('Value Stream Analytics actions / filters', () => {
  let state;
  let stateWithOverview = null;

  describe.each`
    targetAction            | payload                            | mutations
    ${actions.setDateRange} | ${{ createdAfter, createdBefore }} | ${[{ type: 'SET_DATE_RANGE', payload: { createdAfter, createdBefore } }]}
    ${actions.setFilters}   | ${''}                              | ${[]}
  `('$action', ({ targetAction, payload, mutations }) => {
    beforeEach(() => {
      stateWithOverview = { ...state, isOverviewStageSelected: () => true };
    });

    it('dispatches the fetchCycleAnalyticsData action', () => {
      return testAction(targetAction, payload, stateWithOverview, mutations, [
        { type: 'fetchCycleAnalyticsData' },
      ]);
    });

    describe('with a stage selected', () => {
      beforeEach(() => {
        stateWithOverview = { ...state, selectedStage };
      });

      it('dispatches the fetchStageData action', () => {
        return testAction(targetAction, payload, stateWithOverview, mutations, [
          { type: 'fetchStageData', payload: selectedStage.id },
          { type: 'fetchCycleAnalyticsData' },
        ]);
      });
    });
  });

  describe('setSelectedProjects', () => {
    describe('with `overview` stage selected', () => {
      beforeEach(() => {
        stateWithOverview = { ...state, isOverviewStageSelected: () => true };
      });

      it('will dispatch the "fetchCycleAnalyticsData" action', () => {
        return testAction(
          actions.setSelectedProjects,
          selectedProjects,
          stateWithOverview,
          [{ type: types.SET_SELECTED_PROJECTS, payload: selectedProjects }],
          [{ type: 'fetchCycleAnalyticsData' }],
        );
      });
    });

    describe('with non overview stage selected', () => {
      beforeEach(() => {
        state = { ...state, selectedStage };
      });

      it('will dispatch the "fetchStageData" and "fetchCycleAnalyticsData" actions', () => {
        return testAction(
          actions.setSelectedProjects,
          selectedProjects,
          state,
          [{ type: types.SET_SELECTED_PROJECTS, payload: selectedProjects }],
          [
            { type: 'fetchStageData', payload: selectedStage.id },
            { type: 'fetchCycleAnalyticsData' },
          ],
        );
      });
    });
  });

  describe('updateStageTablePagination', () => {
    beforeEach(() => {
      state = { ...state, selectedStage };
    });

    it(`will dispatch the "fetchStageData" action and commit the ${types.SET_PAGINATION} mutation`, () => {
      return testAction({
        action: actions.updateStageTablePagination,
        state,
        expectedMutations: [{ type: types.SET_PAGINATION }],
        expectedActions: [{ type: 'fetchStageData', payload: selectedStage.id }],
      });
    });
  });
});
