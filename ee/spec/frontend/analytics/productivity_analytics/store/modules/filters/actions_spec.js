import { chartKeys } from 'ee/analytics/productivity_analytics/constants';
import * as actions from 'ee/analytics/productivity_analytics/store/modules/filters/actions';
import * as types from 'ee/analytics/productivity_analytics/store/modules/filters/mutation_types';
import getInitialState from 'ee/analytics/productivity_analytics/store/modules/filters/state';
import testAction from 'helpers/vuex_action_helper';
import { mockFilters } from '../../../mock_data';

jest.mock('~/lib/utils/common_utils');
jest.mock('~/lib/utils/url_utility');

describe('Productivity analytics filter actions', () => {
  let store;
  const startDate = new Date('2019-09-01');
  const endDate = new Date('2019-09-07');
  const groupNamespace = 'gitlab-org';
  const projectPath = 'gitlab-org/gitlab-test';
  const initialData = {
    mergedAfter: new Date('2019-11-01'),
    mergedBefore: new Date('2019-12-09'),
    minDate: new Date('2019-01-01'),
  };

  beforeEach(() => {
    store = {
      commit: jest.fn(),
      dispatch: jest.fn(() => Promise.resolve()),
      state: {
        groupNamespace,
      },
    };
  });

  describe('setInitialData', () => {
    it('commits the SET_INITIAL_DATA mutation and fetches data by default', async () => {
      await actions.setInitialData(store, { data: initialData });
      expect(store.commit).toHaveBeenCalledWith(types.SET_INITIAL_DATA, initialData);

      expect(store.dispatch.mock.calls[0]).toEqual([
        'charts/fetchChartData',
        chartKeys.main,
        { root: true },
      ]);

      expect(store.dispatch.mock.calls[1]).toEqual([
        'charts/fetchSecondaryChartData',
        null,
        { root: true },
      ]);

      expect(store.dispatch.mock.calls[2]).toEqual(['table/setPage', 0, { root: true }]);
    });

    it("commits the SET_INITIAL_DATA mutation and doesn't fetch data when skipFetch=true", () =>
      testAction(
        actions.setInitialData,
        { skipFetch: true, data: initialData },
        getInitialState(),
        [
          {
            type: types.SET_INITIAL_DATA,
            payload: initialData,
          },
        ],
        [],
      ));
  });

  describe('setGroupNamespace', () => {
    it('commits the SET_GROUP_NAMESPACE mutation', async () => {
      await actions.setGroupNamespace(store, groupNamespace);
      expect(store.commit).toHaveBeenCalledWith(types.SET_GROUP_NAMESPACE, groupNamespace);

      expect(store.dispatch.mock.calls[0]).toEqual([
        'charts/resetMainChartSelection',
        true,
        { root: true },
      ]);

      expect(store.dispatch.mock.calls[1]).toEqual([
        'charts/fetchChartData',
        chartKeys.main,
        { root: true },
      ]);

      expect(store.dispatch.mock.calls[2]).toEqual([
        'charts/fetchSecondaryChartData',
        null,
        { root: true },
      ]);

      expect(store.dispatch.mock.calls[3]).toEqual(['table/setPage', 0, { root: true }]);
    });
  });

  describe('setProjectPath', () => {
    it('commits the SET_PROJECT_PATH mutation', async () => {
      await actions.setProjectPath(store, projectPath);
      expect(store.commit).toHaveBeenCalledWith(types.SET_PROJECT_PATH, projectPath);

      expect(store.dispatch.mock.calls[0]).toEqual([
        'charts/resetMainChartSelection',
        true,
        { root: true },
      ]);

      expect(store.dispatch.mock.calls[1]).toEqual([
        'charts/fetchChartData',
        chartKeys.main,
        { root: true },
      ]);

      expect(store.dispatch.mock.calls[2]).toEqual([
        'charts/fetchSecondaryChartData',
        null,
        { root: true },
      ]);

      expect(store.dispatch.mock.calls[3]).toEqual(['table/setPage', 0, { root: true }]);
    });
  });

  describe('setFilters', () => {
    it('commits the SET_FILTERS mutation', async () => {
      await actions.setFilters(store, {
        milestone_title: mockFilters.milestoneTitle,
        'not[milestone_title]': mockFilters.notMilestoneTitle,
        author_username: mockFilters.authorUsername,
        'not[author_username]': mockFilters.notAuthorUsername,
        label_name: mockFilters.labelName,
        'not[label_name]': mockFilters.notLabelName,
      });
      expect(store.commit).toHaveBeenCalledWith(types.SET_FILTERS, mockFilters);

      expect(store.dispatch.mock.calls[0]).toEqual([
        'charts/resetMainChartSelection',
        true,
        { root: true },
      ]);

      expect(store.dispatch.mock.calls[1]).toEqual([
        'charts/fetchChartData',
        chartKeys.main,
        { root: true },
      ]);

      expect(store.dispatch.mock.calls[2]).toEqual([
        'charts/fetchSecondaryChartData',
        null,
        { root: true },
      ]);

      expect(store.dispatch.mock.calls[3]).toEqual(['table/setPage', 0, { root: true }]);
    });
  });

  describe('setDateRange', () => {
    it('commits the SET_DATE_RANGE mutation', async () => {
      await actions.setDateRange(store, { startDate, endDate });
      expect(store.commit).toHaveBeenCalledWith(types.SET_DATE_RANGE, { startDate, endDate });

      expect(store.dispatch.mock.calls[0]).toEqual([
        'charts/resetMainChartSelection',
        true,
        { root: true },
      ]);

      expect(store.dispatch.mock.calls[1]).toEqual([
        'charts/fetchChartData',
        chartKeys.main,
        { root: true },
      ]);

      expect(store.dispatch.mock.calls[2]).toEqual([
        'charts/fetchSecondaryChartData',
        null,
        { root: true },
      ]);

      expect(store.dispatch.mock.calls[3]).toEqual(['table/setPage', 0, { root: true }]);
    });
  });
});
