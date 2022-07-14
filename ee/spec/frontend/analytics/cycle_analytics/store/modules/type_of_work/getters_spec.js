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
    it('returns the rootGetters selectedLabelIds if they are any', () => {
      expect(selectedLabelIds(state, getters, null, rootGetters)).toEqual(rootSelectedLabelIds);
    });

    it('returns the topRankedLabelsIds if there are no selectedLabelIds', () => {
      expect(
        selectedLabelIds(null, getters, null, {
          selectedLabelIds: [],
        }),
      ).toEqual(groupLabelIds);
    });
  });
});
