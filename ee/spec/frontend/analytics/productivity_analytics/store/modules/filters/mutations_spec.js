import * as types from 'ee/analytics/productivity_analytics/store/modules/filters/mutation_types';
import mutations from 'ee/analytics/productivity_analytics/store/modules/filters/mutations';
import getInitialState from 'ee/analytics/productivity_analytics/store/modules/filters/state';
import { mockFilters } from '../../../mock_data';

describe('Productivity analytics filter mutations', () => {
  let state;
  const groupNamespace = 'gitlab-org';
  const projectPath = 'gitlab-org/gitlab-test';
  const currentYear = new Date().getFullYear();
  const startDate = new Date(currentYear, 8, 1);
  const endDate = new Date(currentYear, 8, 7);
  const minDate = new Date(currentYear, 0, 1);
  const initializedFilters = {
    authorUsername: null,
    milestoneTitle: null,
    labelName: [],
    notAuthorUsername: null,
    notMilestoneTitle: null,
    notLabelName: [],
  };

  beforeEach(() => {
    state = getInitialState();
  });

  describe(types.SET_INITIAL_DATA, () => {
    it('sets the initial data', () => {
      const initialData = {
        groupNamespace,
        projectPath,
        mergedAfter: startDate,
        mergedBefore: endDate,
        minDate,
        ...mockFilters,
      };
      mutations[types.SET_INITIAL_DATA](state, initialData);

      expect(state.groupNamespace).toBe(groupNamespace);
      expect(state.projectPath).toBe(projectPath);
      expect(state.startDate).toBe(startDate);
      expect(state.endDate).toBe(endDate);
      expect(state.minDate).toBe(minDate);
    });
  });

  describe(types.SET_GROUP_NAMESPACE, () => {
    it('sets the groupNamespace', () => {
      mutations[types.SET_GROUP_NAMESPACE](state, groupNamespace);

      expect(state.groupNamespace).toBe(groupNamespace);
      expect(state.projectPath).toBe(null);

      Object.keys(initializedFilters).forEach((key) => {
        expect(state[key]).toEqual(initializedFilters[key]);
      });
    });
  });

  describe(types.SET_PROJECT_PATH, () => {
    it('sets the projectPath', () => {
      mutations[types.SET_PROJECT_PATH](state, projectPath);

      expect(state.projectPath).toBe(projectPath);

      Object.keys(initializedFilters).forEach((key) => {
        expect(state[key]).toEqual(initializedFilters[key]);
      });
    });
  });

  describe(types.SET_FILTERS, () => {
    it('sets the authorUsername, milestoneTitle and labelName', () => {
      mutations[types.SET_FILTERS](state, mockFilters);

      Object.keys(mockFilters).forEach((key) => {
        expect(state[key]).toBe(mockFilters[key]);
      });
    });
  });

  describe(types.SET_DATE_RANGE, () => {
    it('sets the startDate and endDate', () => {
      mutations[types.SET_DATE_RANGE](state, { startDate, endDate });

      expect(state.startDate).toBe(startDate);
      expect(state.endDate).toBe(endDate);
    });
  });
});
