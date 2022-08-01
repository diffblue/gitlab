import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import {
  TASKS_BY_TYPE_FILTERS,
  TASKS_BY_TYPE_SUBJECT_ISSUE,
} from 'ee/analytics/cycle_analytics/constants';
import * as rootGetters from 'ee/analytics/cycle_analytics/store/getters';
import * as actions from 'ee/analytics/cycle_analytics/store/modules/type_of_work/actions';
import * as getters from 'ee/analytics/cycle_analytics/store/modules/type_of_work/getters';
import * as types from 'ee/analytics/cycle_analytics/store/modules/type_of_work/mutation_types';
import testAction from 'helpers/vuex_action_helper';
import { createdAfter, createdBefore } from 'jest/cycle_analytics/mock_data';
import createFlash from '~/flash';
import httpStatusCodes from '~/lib/utils/http_status';
import { groupLabels, endpoints, rawTasksByTypeData } from '../../../mock_data';

jest.mock('~/flash');

const error = new Error(`Request failed with status code ${httpStatusCodes.NOT_FOUND}`);

describe('Type of work actions', () => {
  let mock;
  let state = {
    isLoadingTasksByTypeChart: false,
    isLoadingTasksByTypeChartTopLabels: false,

    subject: TASKS_BY_TYPE_SUBJECT_ISSUE,
    topRankedLabels: [],
    selectedLabelIds: groupLabels.map(({ id }) => id),
    data: [],
  };

  const mockedState = {
    ...rootGetters,
    ...getters,
    ...state,
    rootState: { createdAfter, createdBefore },
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
    state = { ...mockedState, selectedGroup: null };
  });

  describe('setLoading', () => {
    it(`commits the '${types.SET_LOADING}' action`, () => {
      return testAction(
        actions.setLoading,
        true,
        state,
        [{ type: types.SET_LOADING, payload: true }],
        [],
      );
    });
  });

  describe('fetchTopRankedGroupLabels', () => {
    beforeEach(() => {
      gon.api_version = 'v4';
      state = { ...mockedState, subject: TASKS_BY_TYPE_SUBJECT_ISSUE };
    });

    describe('succeeds', () => {
      beforeEach(() => {
        mock.onGet(endpoints.tasksByTypeTopLabelsData).replyOnce(httpStatusCodes.OK, groupLabels);
      });

      it('dispatches receiveTopRankedGroupLabelsSuccess if the request succeeds', () => {
        return testAction(
          actions.fetchTopRankedGroupLabels,
          null,
          state,
          [{ type: 'REQUEST_TOP_RANKED_GROUP_LABELS' }],
          [{ type: 'receiveTopRankedGroupLabelsSuccess', payload: groupLabels }],
        );
      });

      describe('receiveTopRankedGroupLabelsSuccess', () => {
        it(`commits the ${types.RECEIVE_TOP_RANKED_GROUP_LABELS_SUCCESS} mutation and dispatches the 'fetchTasksByTypeData' action`, () => {
          return testAction(
            actions.receiveTopRankedGroupLabelsSuccess,
            null,
            state,
            [
              {
                type: types.RECEIVE_TOP_RANKED_GROUP_LABELS_SUCCESS,
                payload: null,
              },
            ],
            [{ type: 'fetchTasksByTypeData' }],
          );
        });
      });
    });

    describe(`Status ${httpStatusCodes.OK} and error message in response`, () => {
      const dataError = 'Too much data';

      beforeEach(() => {
        mock
          .onGet(endpoints.tasksByTypeTopLabelsData)
          .reply(httpStatusCodes.OK, { error: dataError });
      });

      it(`dispatches the 'receiveTopRankedGroupLabelsError' with ${dataError}`, () => {
        return testAction(
          actions.fetchTopRankedGroupLabels,
          null,
          state,
          [
            {
              type: types.REQUEST_TOP_RANKED_GROUP_LABELS,
            },
          ],
          [{ type: 'receiveTopRankedGroupLabelsError', payload: new Error(dataError) }],
        );
      });
    });

    describe('with an error', () => {
      beforeEach(() => {
        mock.onGet(endpoints.fetchTopRankedGroupLabels).replyOnce(httpStatusCodes.NOT_FOUND);
      });

      it('dispatches receiveTopRankedGroupLabelsError if the request fails', () => {
        return testAction(
          actions.fetchTopRankedGroupLabels,
          null,
          state,
          [{ type: 'REQUEST_TOP_RANKED_GROUP_LABELS' }],
          [{ type: 'receiveTopRankedGroupLabelsError', payload: error }],
        );
      });
    });

    describe('receiveTopRankedGroupLabelsError', () => {
      it('flashes an error message if the request fails', () => {
        actions.receiveTopRankedGroupLabelsError({
          commit: () => {},
        });

        expect(createFlash).toHaveBeenCalledWith({
          message: 'There was an error fetching the top labels for the selected group',
        });
      });
    });
  });

  describe('fetchTasksByTypeData', () => {
    beforeEach(() => {
      gon.api_version = 'v4';
      state = { ...mockedState, subject: TASKS_BY_TYPE_SUBJECT_ISSUE };
    });

    describe('succeeds', () => {
      beforeEach(() => {
        mock.onGet(endpoints.tasksByTypeData).replyOnce(httpStatusCodes.OK, rawTasksByTypeData);
      });

      it(`commits the ${types.RECEIVE_TASKS_BY_TYPE_DATA_SUCCESS} if the request succeeds`, () => {
        return testAction(
          actions.fetchTasksByTypeData,
          null,
          state,
          [
            { type: types.REQUEST_TASKS_BY_TYPE_DATA },
            { type: types.RECEIVE_TASKS_BY_TYPE_DATA_SUCCESS, payload: rawTasksByTypeData },
          ],
          [],
        );
      });
    });

    describe(`Status ${httpStatusCodes.OK} and error message in response`, () => {
      const dataError = 'Too much data';

      beforeEach(() => {
        mock.onGet(endpoints.tasksByTypeData).reply(httpStatusCodes.OK, { error: dataError });
      });

      it(`dispatches the 'receiveTasksByTypeDataError' with ${dataError}`, () => {
        return testAction(
          actions.fetchTasksByTypeData,
          null,
          state,
          [{ type: types.REQUEST_TASKS_BY_TYPE_DATA }],
          [{ type: 'receiveTasksByTypeDataError', payload: new Error(dataError) }],
        );
      });
    });

    describe('with an error', () => {
      beforeEach(() => {
        mock.onGet(endpoints.fetchTasksByTypeData).replyOnce(httpStatusCodes.NOT_FOUND);
      });

      it('dispatches receiveTasksByTypeDataError if the request fails', () => {
        return testAction(
          actions.fetchTasksByTypeData,
          null,
          state,
          [{ type: 'REQUEST_TASKS_BY_TYPE_DATA' }],
          [{ type: 'receiveTasksByTypeDataError', payload: error }],
        );
      });
    });

    describe('receiveTasksByTypeDataError', () => {
      it('flashes an error message if the request fails', () => {
        actions.receiveTasksByTypeDataError({
          commit: () => {},
        });

        expect(createFlash).toHaveBeenCalledWith({
          message: 'There was an error fetching data for the tasks by type chart',
        });
      });
    });
  });

  describe('setTasksByTypeFilters', () => {
    const filter = TASKS_BY_TYPE_FILTERS.SUBJECT;
    const value = 'issue';

    it(`commits the ${types.SET_TASKS_BY_TYPE_FILTERS} mutation and dispatches 'fetchTasksByTypeData'`, () => {
      return testAction(
        actions.setTasksByTypeFilters,
        { filter, value },
        {},
        [
          {
            type: types.SET_TASKS_BY_TYPE_FILTERS,
            payload: { filter, value },
          },
        ],
        [
          {
            type: 'fetchTasksByTypeData',
          },
        ],
      );
    });
  });
});
