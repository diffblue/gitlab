import {
  tasksByTypeChartData,
  topRankedLabelsIds,
  selectedLabelIds,
} from 'ee/analytics/cycle_analytics/store/modules/type_of_work/getters';
import { createdAfter, createdBefore } from 'jest/cycle_analytics/mock_data';
import {
  rawTasksByTypeData,
  transformedTasksByTypeData,
  groupLabels,
  groupLabelIds,
} from '../../../mock_data';

const rootSelectedLabelIds = [1, 2, 3];
const state = { topRankedLabels: groupLabels };
const rootGetters = { selectedLabelIds: rootSelectedLabelIds };
const getters = { topRankedLabelsIds: groupLabelIds };

describe('Type of work getters', () => {
  describe('tasksByTypeChartData', () => {
    const rootState = { createdAfter, createdBefore };
    describe('with data', () => {
      it('correctly transforms the raw task by type data', () => {
        expect(tasksByTypeChartData(rawTasksByTypeData, null, rootState)).toEqual(
          transformedTasksByTypeData,
        );
      });
    });

    describe('with no data', () => {
      it('returns all required properties', () => {
        expect(tasksByTypeChartData()).toEqual({ groupBy: [], data: [] });
      });
    });
  });

  describe('topRankedLabelsIds', () => {
    it('returns the ids of the topRankedLabels state array', () => {
      expect(topRankedLabelsIds(state)).toEqual(groupLabelIds);
    });
  });

  describe('selectedLabelIds', () => {
    it.each`
      key                               | condition                                      | rootGettersValue            | result
      ${'rootGetters selectedLabelIds'} | ${'are rootGetter selectedLabelIds available'} | ${rootGetters}              | ${rootSelectedLabelIds}
      ${'topRankedLabelsIds'}           | ${'no rootGetter selectedLabelIds'}            | ${{ selectedLabelIds: [] }} | ${groupLabelIds}
    `('returns the $key when there $condition', ({ rootGettersValue, result }) => {
      expect(selectedLabelIds(state, getters, null, rootGettersValue)).toEqual(result);
    });
  });
});
