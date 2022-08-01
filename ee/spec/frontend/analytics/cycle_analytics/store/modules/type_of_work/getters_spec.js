import {
  tasksByTypeChartData,
  selectedTasksByTypeFilters,
} from 'ee/analytics/cycle_analytics/store/modules/type_of_work/getters';
import { TASKS_BY_TYPE_SUBJECT_ISSUE } from 'ee/analytics/cycle_analytics/constants';
import { createdAfter, createdBefore } from 'jest/cycle_analytics/mock_data';
import {
  rawTasksByTypeData,
  transformedTasksByTypeData,
  groupLabels,
  currentGroup,
} from '../../../mock_data';

const selectedProjectIds = [1, 2];
const rootSelectedLabelIds = [1, 2, 3];
const state = {
  topRankedLabels: groupLabels,
  subject: TASKS_BY_TYPE_SUBJECT_ISSUE,
  selectedLabelIds: rootSelectedLabelIds,
};
const rootState = {
  topRankedLabels: groupLabels,
  createdAfter,
  createdBefore,
  currentGroup,
};
const rootGetters = { selectedProjectIds, selectedLabelIds: rootSelectedLabelIds };

describe('Type of work getters', () => {
  describe('tasksByTypeChartData', () => {
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

  describe('selectedTasksByTypeFilters', () => {
    it('returns all the task by type filter key', () => {
      const keys = Object.keys(selectedTasksByTypeFilters(state));

      [
        'currentGroup',
        'selectedProjectIds',
        'createdAfter',
        'createdBefore',
        'selectedLabelIds',
        'subject',
      ].forEach((key) => {
        expect(keys).toContain(key);
      });
    });

    it('sets the correct value for each key', () => {
      const result = selectedTasksByTypeFilters(state, null, rootState, rootGetters);

      expect(result.currentGroup).toEqual(currentGroup);
      expect(result.selectedLabelIds).toEqual(rootSelectedLabelIds);
      expect(result.selectedProjectIds).toEqual(selectedProjectIds);
      expect(result.subject).toEqual(TASKS_BY_TYPE_SUBJECT_ISSUE);
      expect(result.createdBefore).toEqual(createdBefore);
      expect(result.createdAfter).toEqual(createdAfter);
    });
  });
});
