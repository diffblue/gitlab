import {
  REPORT_STATUS,
  SORT_ASCENDING,
  SORT_DESCENDING,
} from 'ee/dependencies/store/modules/list/constants';
import * as types from 'ee/dependencies/store/modules/list/mutation_types';
import mutations from 'ee/dependencies/store/modules/list/mutations';
import getInitialState from 'ee/dependencies/store/modules/list/state';
import { TEST_HOST } from 'helpers/test_constants';

describe('Dependencies mutations', () => {
  let state;

  beforeEach(() => {
    state = getInitialState();
  });

  describe(types.SET_DEPENDENCIES_ENDPOINT, () => {
    it('sets the endpoint', () => {
      mutations[types.SET_DEPENDENCIES_ENDPOINT](state, TEST_HOST);

      expect(state.endpoint).toBe(TEST_HOST);
    });
  });

  describe(types.SET_EXPORT_DEPENDENCIES_ENDPOINT, () => {
    it('sets the export endpoint', () => {
      mutations[types.SET_EXPORT_DEPENDENCIES_ENDPOINT](state, TEST_HOST);

      expect(state.exportEndpoint).toBe(TEST_HOST);
    });
  });

  describe(types.SET_FETCHING_IN_PROGRESS, () => {
    it('sets if export is being fetched', () => {
      mutations[types.SET_FETCHING_IN_PROGRESS](state, true);

      expect(state.fetchingInProgress).toBe(true);
    });
  });

  describe(types.SET_INITIAL_STATE, () => {
    it('correctly mutates the state', () => {
      const filter = 'foo';
      mutations[types.SET_INITIAL_STATE](state, { filter });

      expect(state.filter).toBe(filter);
    });
  });

  describe(types.REQUEST_DEPENDENCIES, () => {
    beforeEach(() => {
      mutations[types.REQUEST_DEPENDENCIES](state);
    });

    it('correctly mutates the state', () => {
      expect(state.isLoading).toBe(true);
      expect(state.errorLoading).toBe(false);
    });
  });

  describe(types.RECEIVE_DEPENDENCIES_SUCCESS, () => {
    const dependencies = [];
    const pageInfo = {};
    const reportInfo = {
      status: REPORT_STATUS.jobFailed,
      job_path: 'foo',
      generated_at: 'foo',
    };

    beforeEach(() => {
      mutations[types.RECEIVE_DEPENDENCIES_SUCCESS](state, { dependencies, reportInfo, pageInfo });
    });

    it('correctly mutates the state', () => {
      expect(state.isLoading).toBe(false);
      expect(state.errorLoading).toBe(false);
      expect(state.dependencies).toBe(dependencies);
      expect(state.pageInfo).toBe(pageInfo);
      expect(state.initialized).toBe(true);
      expect(state.reportInfo).toEqual({
        status: REPORT_STATUS.jobFailed,
        jobPath: 'foo',
        generatedAt: 'foo',
      });
    });
  });

  describe(types.RECEIVE_DEPENDENCIES_ERROR, () => {
    beforeEach(() => {
      mutations[types.RECEIVE_DEPENDENCIES_ERROR](state);
    });

    it('correctly mutates the state', () => {
      expect(state.isLoading).toBe(false);
      expect(state.errorLoading).toBe(true);
      expect(state.dependencies).toEqual([]);
      expect(state.pageInfo).toEqual({});
      expect(state.initialized).toBe(true);
      expect(state.reportInfo).toEqual({
        status: REPORT_STATUS.ok,
        jobPath: '',
        generatedAt: '',
      });
    });
  });

  describe(types.SET_SORT_FIELD, () => {
    it.each`
      field         | order
      ${'name'}     | ${SORT_ASCENDING}
      ${'packager'} | ${SORT_ASCENDING}
      ${'severity'} | ${SORT_DESCENDING}
      ${'foo'}      | ${undefined}
    `('sets the sort field to $field and sort order to $order', ({ field, order }) => {
      mutations[types.SET_SORT_FIELD](state, field);

      expect(state.sortField).toBe(field);
      expect(state.sortOrder).toBe(order);
    });
  });

  describe(types.TOGGLE_SORT_ORDER, () => {
    it('toggles the sort order', () => {
      const sortState = { sortOrder: SORT_ASCENDING };
      mutations[types.TOGGLE_SORT_ORDER](sortState);

      expect(sortState.sortOrder).toBe(SORT_DESCENDING);

      mutations[types.TOGGLE_SORT_ORDER](sortState);

      expect(sortState.sortOrder).toBe(SORT_ASCENDING);
    });
  });
});
