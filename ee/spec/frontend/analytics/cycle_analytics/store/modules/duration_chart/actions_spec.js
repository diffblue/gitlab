import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import * as rootGetters from 'ee/analytics/cycle_analytics/store/getters';
import * as actions from 'ee/analytics/cycle_analytics/store/modules/duration_chart/actions';
import * as getters from 'ee/analytics/cycle_analytics/store/modules/duration_chart/getters';
import * as types from 'ee/analytics/cycle_analytics/store/modules/duration_chart/mutation_types';
import testAction from 'helpers/vuex_action_helper';
import { createdAfter, createdBefore, group } from 'jest/analytics/cycle_analytics/mock_data';
import { createAlert } from '~/alert';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import {
  allowedStages as activeStages,
  transformedDurationData,
  endpoints,
  valueStreams,
} from '../../../mock_data';

jest.mock('~/alert');
const selectedGroup = { fullPath: group.path };
const hiddenStage = { ...activeStages[0], hidden: true, id: 3, slug: 3 };
const [selectedValueStream] = valueStreams;
const error = new Error(`Request failed with status code ${HTTP_STATUS_BAD_REQUEST}`);

const rootState = {
  createdAfter,
  createdBefore,
  stages: [...activeStages, hiddenStage],
  selectedGroup,
  selectedValueStream,
  features: {},
};

describe('DurationChart actions', () => {
  let mock;
  const state = {
    ...rootState,
    ...getters,
    ...rootGetters,
    activeStages,
    currentGroupPath: () => selectedGroup.fullPath,
    currentValueStreamId: () => selectedValueStream.id,
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
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

  describe('fetchDurationData', () => {
    beforeEach(() => {
      // The first 2 stages have different duration values
      mock
        .onGet(endpoints.durationData)
        .replyOnce(HTTP_STATUS_OK, transformedDurationData[0].data)
        .onGet(endpoints.durationData)
        .replyOnce(HTTP_STATUS_OK, transformedDurationData[1].data);

      // all subsequent requests should get the same data
      mock.onGet(endpoints.durationData).reply(HTTP_STATUS_OK, transformedDurationData[2].data);
    });

    it("dispatches the 'requestDurationData' and 'receiveDurationDataSuccess' actions on success", () => {
      return testAction(
        actions.fetchDurationData,
        null,
        state,
        [
          {
            type: types.RECEIVE_DURATION_DATA_SUCCESS,
            payload: transformedDurationData,
          },
        ],
        [{ type: 'requestDurationData' }],
      );
    });

    it('does not request hidden stages', () => {
      const dispatch = jest.fn();
      return actions
        .fetchDurationData({
          dispatch,
          rootState,
          rootGetters: {
            ...rootGetters,
            activeStages,
          },
        })
        .then(() => {
          const requestedUrls = mock.history.get.map(({ url }) => url);
          expect(requestedUrls).not.toContain(
            `/groups/foo/-/analytics/value_stream_analytics/stages/${hiddenStage.id}/duration_chart`,
          );
        });
    });

    describe(`Status ${HTTP_STATUS_OK} and error message in response`, () => {
      const dataError = 'Too much data';

      beforeEach(() => {
        mock.onGet(endpoints.durationData).reply(HTTP_STATUS_OK, { error: dataError });
      });

      it(`dispatches the 'receiveDurationDataError' with ${dataError}`, () => {
        const dispatch = jest.fn();
        const commit = jest.fn();

        return actions
          .fetchDurationData({
            dispatch,
            commit,
            rootState,
            rootGetters: {
              ...rootGetters,
              activeStages,
            },
          })
          .then(() => {
            expect(commit).not.toHaveBeenCalled();
            expect(dispatch.mock.calls).toEqual([
              ['requestDurationData'],
              ['receiveDurationDataError', new Error(dataError)],
            ]);
          });
      });
    });

    describe('receiveDurationDataError', () => {
      beforeEach(() => {
        mock.onGet(endpoints.durationData).reply(HTTP_STATUS_BAD_REQUEST, error);
      });

      it("dispatches the 'receiveDurationDataError' action when there is an error", () => {
        const dispatch = jest.fn();

        return actions
          .fetchDurationData({
            dispatch,
            rootState,
            rootGetters: {
              ...rootGetters,
              activeStages,
            },
          })
          .then(() => {
            expect(dispatch.mock.calls).toEqual([
              ['requestDurationData'],
              ['receiveDurationDataError', error],
            ]);
          });
      });
    });
  });

  describe('receiveDurationDataError', () => {
    it("commits the 'RECEIVE_DURATION_DATA_ERROR' mutation", () => {
      testAction(
        actions.receiveDurationDataError,
        {},
        rootState,
        [
          {
            type: types.RECEIVE_DURATION_DATA_ERROR,
            payload: {},
          },
        ],
        [],
      );
    });

    it('will alert an error', () => {
      actions.receiveDurationDataError({
        commit: () => {},
      });

      expect(createAlert).toHaveBeenCalledWith({
        message: 'There was an error while fetching value stream analytics duration data.',
      });
    });
  });
});
