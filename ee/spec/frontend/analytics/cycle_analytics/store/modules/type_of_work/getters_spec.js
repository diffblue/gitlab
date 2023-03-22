import {
  tasksByTypeChartData,
  selectedTasksByTypeFilters,
  selectedLabelIds,
  selectedLabelNames,
} from 'ee/analytics/cycle_analytics/store/modules/type_of_work/getters';
import { TASKS_BY_TYPE_SUBJECT_ISSUE } from 'ee/analytics/cycle_analytics/constants';
import { createdAfter, createdBefore } from 'jest/analytics/cycle_analytics/mock_data';
import {
  rawTasksByTypeData,
  transformedTasksByTypeData,
  groupLabels,
  groupLabelIds,
  groupLabelNames,
  currentGroup as namespace,
} from '../../../mock_data';

const selectedProjectIds = [1, 2];
const state = {
  topRankedLabels: groupLabels,
  subject: TASKS_BY_TYPE_SUBJECT_ISSUE,
  selectedLabels: groupLabels,
};
const rootState = {
  topRankedLabels: groupLabels,
  createdAfter,
  createdBefore,
  namespace,
  defaultGroupLabels: groupLabels,
};
const rootGetters = { selectedProjectIds };

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

      ['namespace', 'selectedProjectIds', 'createdAfter', 'createdBefore', 'subject'].forEach(
        (key) => {
          expect(keys).toContain(key);
        },
      );
    });

    it('sets the correct value for each key', () => {
      const result = selectedTasksByTypeFilters(state, null, rootState, rootGetters);

      expect(result.namespace).toEqual(namespace);
      expect(result.selectedProjectIds).toEqual(selectedProjectIds);
      expect(result.subject).toEqual(TASKS_BY_TYPE_SUBJECT_ISSUE);
      expect(result.createdBefore).toEqual(createdBefore);
      expect(result.createdAfter).toEqual(createdAfter);
    });
  });

  describe('selectedLabelIds', () => {
    it.each`
      getterState | expected
      ${state}    | ${groupLabelIds}
      ${{}}       | ${[]}
    `('returns an array of matching label ids', ({ getterState, getterRootState, expected }) => {
      const result = selectedLabelIds(getterState, null, getterRootState);
      expect(result).toEqual(expected);
    });
  });

  describe('selectedLabelNames', () => {
    it.each`
      getterState | expected
      ${state}    | ${groupLabelNames}
      ${{}}       | ${[]}
    `('returns an array of matching label names', ({ getterState, getterRootState, expected }) => {
      const result = selectedLabelNames(getterState, null, getterRootState);
      expect(result).toEqual(expected);
    });
  });
});
