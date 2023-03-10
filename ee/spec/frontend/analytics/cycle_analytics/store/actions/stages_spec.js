import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { OVERVIEW_STAGE_CONFIG } from 'ee/analytics/cycle_analytics/constants';
import * as actions from 'ee/analytics/cycle_analytics/store/actions/stages';
import * as getters from 'ee/analytics/cycle_analytics/store/getters';
import * as types from 'ee/analytics/cycle_analytics/store/mutation_types';
import testAction from 'helpers/vuex_action_helper';
import {
  createdAfter,
  createdBefore,
  currentGroup,
} from 'jest/analytics/cycle_analytics/mock_data';
import {
  I18N_VSA_ERROR_STAGES,
  I18N_VSA_ERROR_STAGE_MEDIAN,
  I18N_VSA_ERROR_SELECTED_STAGE,
} from '~/analytics/cycle_analytics/constants';
import { createAlert } from '~/alert';
import { HTTP_STATUS_NOT_FOUND, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import {
  allowedStages as stages,
  customizableStagesAndEvents,
  endpoints,
  valueStreams,
} from '../../mock_data';

const stageData = { events: [] };
const error = new Error(`Request failed with status code ${HTTP_STATUS_NOT_FOUND}`);

stages[0].hidden = true;
const activeStages = stages.filter(({ hidden }) => !hidden);
const hiddenStage = stages[0];

const [selectedStage] = activeStages;
const selectedStageSlug = selectedStage.slug;
const [selectedValueStream] = valueStreams;

const selectedProjectIds = [1, 2];

const mockGetters = {
  currentGroupPath: () => currentGroup.fullPath,
  currentValueStreamId: () => selectedValueStream.id,
  cycleAnalyticsRequestParams: () => ({
    created_after: createdAfter,
    project_ids: selectedProjectIds,
  }),
};

jest.mock('~/alert');

describe('Value Stream Analytics actions / stages', () => {
  let state;
  let mock;

  beforeEach(() => {
    state = {
      createdAfter,
      createdBefore,
      stages: [],
      features: {},
      activeStages,
      selectedValueStream,
      ...mockGetters,
    };
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
    state = { ...state, currentGroup: null };
  });

  describe('setSelectedStage', () => {
    const data = { id: 'someStageId' };

    it(`dispatches the ${types.SET_SELECTED_STAGE} and ${types.SET_PAGINATION} actions`, () => {
      return testAction(actions.setSelectedStage, data, { ...state, selectedValueStream: {} }, [
        { type: types.SET_SELECTED_STAGE, payload: data },
      ]);
    });
  });

  describe('setDefaultSelectedStage', () => {
    it("dispatches the 'setSelectedStage' with the overview stage", () => {
      return testAction(
        actions.setDefaultSelectedStage,
        null,
        state,
        [],
        [{ type: 'setSelectedStage', payload: OVERVIEW_STAGE_CONFIG }],
      );
    });
  });

  describe('requestStageData', () => {
    it(`commits the ${types.REQUEST_STAGE_DATA} mutation`, () => {
      return testAction({
        action: actions.requestStageData,
        expectedMutations: [{ type: types.REQUEST_STAGE_DATA }],
      });
    });
  });

  describe('fetchStageData', () => {
    const headers = {
      'X-Next-Page': 2,
      'X-Page': 1,
    };

    beforeEach(() => {
      state = { ...state, currentGroup };
      mock = new MockAdapter(axios);
      mock.onGet(endpoints.stageData).reply(HTTP_STATUS_OK, stageData, headers);
    });

    it(`commits ${types.RECEIVE_STAGE_DATA_SUCCESS} with received data and headers on success`, () => {
      return testAction(
        actions.fetchStageData,
        selectedStageSlug,
        state,
        [
          {
            type: types.RECEIVE_STAGE_DATA_SUCCESS,
            payload: stageData,
          },
          {
            type: types.SET_PAGINATION,
            payload: { page: headers['X-Page'], hasNextPage: true },
          },
        ],
        [{ type: 'requestStageData' }],
      );
    });

    describe('without a next page', () => {
      beforeEach(() => {
        mock = new MockAdapter(axios);
        mock
          .onGet(endpoints.stageData)
          .reply(HTTP_STATUS_OK, { events: [] }, { ...headers, 'X-Next-Page': null });
      });

      it('sets hasNextPage to false', () => {
        return testAction(
          actions.fetchStageData,
          selectedStageSlug,
          state,
          [
            {
              type: types.RECEIVE_STAGE_DATA_SUCCESS,
              payload: { events: [] },
            },
            {
              type: types.SET_PAGINATION,
              payload: { page: headers['X-Page'], hasNextPage: false },
            },
          ],
          [{ type: 'requestStageData' }],
        );
      });
    });

    describe('with a failing request', () => {
      beforeEach(() => {
        mock = new MockAdapter(axios);
        mock.onGet(endpoints.stageData).replyOnce(HTTP_STATUS_NOT_FOUND, { error });
      });

      it('dispatches receiveStageDataError on error', () => {
        return testAction(
          actions.fetchStageData,
          selectedStage,
          state,
          [],
          [
            {
              type: 'requestStageData',
            },
            {
              type: 'receiveStageDataError',
              payload: error,
            },
          ],
        );
      });
    });
  });

  describe('receiveStageDataError', () => {
    const message = 'fake error';

    it(`commits the ${types.RECEIVE_STAGE_DATA_ERROR} mutation`, () => {
      return testAction(
        actions.receiveStageDataError,
        { message },
        state,
        [
          {
            type: types.RECEIVE_STAGE_DATA_ERROR,
            payload: message,
          },
        ],
        [],
      );
    });

    it('will alert an error message', () => {
      actions.receiveStageDataError({ commit: () => {} }, {});
      expect(createAlert).toHaveBeenCalledWith({ message: I18N_VSA_ERROR_SELECTED_STAGE });
    });
  });

  describe('requestStageMedianValues', () => {
    it(`commits the ${types.REQUEST_STAGE_MEDIANS} mutation`, () => {
      return testAction({
        action: actions.requestStageMedianValues,
        expectedMutations: [{ type: types.REQUEST_STAGE_MEDIANS }],
      });
    });
  });

  describe('fetchStageMedianValues', () => {
    let mockDispatch = jest.fn();
    const fetchMedianResponse = activeStages.map(({ id }) => ({ events: [], id }));

    beforeEach(() => {
      state = { ...state, stages, currentGroup };
      mock = new MockAdapter(axios);
      mock.onGet(endpoints.stageMedian).reply(HTTP_STATUS_OK, { events: [] });
      mockDispatch = jest.fn();
    });

    it('dispatches receiveStageMedianValuesSuccess with received data on success', () => {
      return testAction(
        actions.fetchStageMedianValues,
        null,
        state,
        [{ type: types.RECEIVE_STAGE_MEDIANS_SUCCESS, payload: fetchMedianResponse }],
        [{ type: 'requestStageMedianValues' }],
      );
    });

    it('does not request hidden stages', () => {
      return actions
        .fetchStageMedianValues({
          state,
          getters: {
            ...getters,
            activeStages,
          },
          commit: () => {},
          dispatch: mockDispatch,
        })
        .then(() => {
          expect(mockDispatch).not.toHaveBeenCalledWith('receiveStageMedianValuesSuccess', {
            events: [],
            id: hiddenStage.id,
          });
        });
    });

    describe(`Status ${HTTP_STATUS_OK} and error message in response`, () => {
      const dataError = 'Too much data';
      const payload = activeStages.map(({ id }) => ({ value: null, id, error: dataError }));

      beforeEach(() => {
        mock.onGet(endpoints.stageMedian).reply(HTTP_STATUS_OK, { error: dataError });
      });

      it(`dispatches the 'RECEIVE_STAGE_MEDIANS_SUCCESS' with ${dataError}`, () => {
        return testAction(
          actions.fetchStageMedianValues,
          null,
          state,
          [{ type: types.RECEIVE_STAGE_MEDIANS_SUCCESS, payload }],
          [{ type: 'requestStageMedianValues' }],
        );
      });
    });

    describe('with a failing request', () => {
      beforeEach(() => {
        mock.onGet(endpoints.stageMedian).reply(HTTP_STATUS_NOT_FOUND, { error });
      });

      it('will dispatch receiveStageMedianValuesError', () => {
        return testAction(
          actions.fetchStageMedianValues,
          null,
          state,
          [],
          [
            { type: 'requestStageMedianValues' },
            { type: 'receiveStageMedianValuesError', payload: error },
          ],
        );
      });
    });
  });

  describe('receiveStageMedianValuesError', () => {
    it(`commits the ${types.RECEIVE_STAGE_MEDIANS_ERROR} mutation`, () =>
      testAction(
        actions.receiveStageMedianValuesError,
        {},
        state,
        [
          {
            type: types.RECEIVE_STAGE_MEDIANS_ERROR,
            payload: {},
          },
        ],
        [],
      ));

    it('will alert an error message', () => {
      actions.receiveStageMedianValuesError({ commit: () => {} });
      expect(createAlert).toHaveBeenCalledWith({ message: I18N_VSA_ERROR_STAGE_MEDIAN });
    });
  });

  describe('fetchStageCountValues', () => {
    const fetchCountResponse = activeStages.map(({ id }) => ({ events: [], id }));

    beforeEach(() => {
      state = {
        ...state,
        stages,
        currentGroup,
        features: state.features,
      };
      mock = new MockAdapter(axios);
      mock.onGet(endpoints.stageCount).reply(HTTP_STATUS_OK, { events: [] });
    });

    it('dispatches receiveStageCountValuesSuccess with received data on success', () => {
      return testAction(
        actions.fetchStageCountValues,
        null,
        state,
        [
          { type: types.REQUEST_STAGE_COUNTS },
          { type: types.RECEIVE_STAGE_COUNTS_SUCCESS, payload: fetchCountResponse },
        ],
        [],
      );
    });
  });

  describe('requestGroupStages', () => {
    it(`commits the ${types.REQUEST_GROUP_STAGES} mutation`, () => {
      return testAction({
        action: actions.requestGroupStages,
        expectedMutations: [{ type: types.REQUEST_GROUP_STAGES }],
      });
    });
  });

  describe('receiveGroupStagesError', () => {
    it(`commits the ${types.RECEIVE_GROUP_STAGES_ERROR} mutation`, () => {
      return testAction({
        action: actions.receiveGroupStagesError,
        expectedMutations: [{ type: types.RECEIVE_GROUP_STAGES_ERROR }],
      });
    });

    it('will alert an error message', async () => {
      expect(createAlert).not.toHaveBeenCalled();

      await actions.receiveGroupStagesError({ commit: () => {} });

      expect(createAlert).toHaveBeenCalledWith({ message: I18N_VSA_ERROR_STAGES });
    });
  });

  describe('receiveGroupStagesSuccess', () => {
    it(`commits the ${types.RECEIVE_GROUP_STAGES_SUCCESS} mutation'`, () => {
      return testAction(
        actions.receiveGroupStagesSuccess,
        { ...customizableStagesAndEvents.stages },
        state,
        [
          {
            type: types.RECEIVE_GROUP_STAGES_SUCCESS,
            payload: { ...customizableStagesAndEvents.stages },
          },
        ],
        [],
      );
    });
  });

  describe('fetchGroupStagesAndEvents', () => {
    const { stages: groupStages, events } = customizableStagesAndEvents;

    beforeEach(() => {
      state = { ...state, ...mockGetters };
      mock = new MockAdapter(axios);
      mock.onGet(endpoints.baseStagesEndpoint).reply(HTTP_STATUS_OK, customizableStagesAndEvents);
    });

    it(`commits ${types.RECEIVE_STAGE_DATA_SUCCESS} with received data and headers on success`, () => {
      return testAction({
        action: actions.fetchGroupStagesAndEvents,
        state,
        expectedMutations: [
          { type: types.SET_STAGE_EVENTS, payload: [] },
          {
            type: types.SET_STAGE_EVENTS,
            payload: events,
          },
        ],
        expectedActions: [
          { type: 'requestGroupStages' },
          { type: 'receiveGroupStagesSuccess', payload: groupStages },
        ],
      });
    });

    describe('with a failing request', () => {
      beforeEach(() => {
        mock = new MockAdapter(axios);
        mock.onGet(endpoints.baseStagesEndpoint).replyOnce(HTTP_STATUS_NOT_FOUND, { error });
      });

      it('dispatches receiveGroupStagesError on error', () => {
        return testAction({
          action: actions.fetchGroupStagesAndEvents,
          state,
          expectedMutations: [{ type: types.SET_STAGE_EVENTS, payload: [] }],
          expectedActions: [
            { type: 'requestGroupStages' },
            {
              type: 'receiveGroupStagesError',
              payload: error,
            },
          ],
        });
      });
    });
  });
});
