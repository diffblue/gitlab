import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import * as actions from 'ee/analytics/cycle_analytics/store/actions';
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
} from '~/analytics/cycle_analytics/constants';
import { createAlert } from '~/flash';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { allowedStages as stages, valueStreams, endpoints, groupLabels } from '../mock_data';

const group = { fullPath: 'fake_group_full_path' };
const milestonesPath = 'fake_milestones_path.json';
const labelsPath = 'fake_labels_path.json';

const flashErrorMessage = 'There was an error while fetching value stream analytics data.';

stages[0].hidden = true;
const activeStages = stages.filter(({ hidden }) => !hidden);
const [selectedValueStream] = valueStreams;

const mockGetters = {
  currentGroupPath: () => currentGroup.fullPath,
  currentValueStreamId: () => selectedValueStream.id,
};

jest.mock('~/flash');

describe('Value Stream Analytics actions', () => {
  let state;
  let mock;

  beforeEach(() => {
    state = {
      createdAfter,
      createdBefore,
      stages: [],
      featureFlags: {},
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

  it.each`
    action               | type                   | stateKey          | payload
    ${'setFeatureFlags'} | ${'SET_FEATURE_FLAGS'} | ${'featureFlags'} | ${{ someFeatureFlag: true }}
  `('$action should set $stateKey with $payload and type $type', ({ action, type, payload }) => {
    return testAction(
      actions[action],
      payload,
      state,
      [
        {
          type,
          payload,
        },
      ],
      [],
    );
  });

  describe('setPaths', () => {
    it('dispatches the filters/setEndpoints action with enpoints', () => {
      return testAction(
        actions.setPaths,
        { groupPath: group.fullPath, milestonesPath, labelsPath },
        state,
        [],
        [
          {
            type: 'filters/setEndpoints',
            payload: {
              groupEndpoint: 'fake_group_full_path',
              labelsEndpoint: labelsPath,
              milestonesEndpoint: milestonesPath,
            },
          },
        ],
      );
    });
  });

  describe('fetchCycleAnalyticsData', () => {
    function mockFetchCycleAnalyticsAction(overrides = {}) {
      const mocks = {
        requestCycleAnalyticsData:
          overrides.requestCycleAnalyticsData || jest.fn().mockResolvedValue(),
        fetchStageMedianValues: overrides.fetchStageMedianValues || jest.fn().mockResolvedValue(),
        fetchGroupStagesAndEvents:
          overrides.fetchGroupStagesAndEvents || jest.fn().mockResolvedValue(),
        receiveCycleAnalyticsDataSuccess:
          overrides.receiveCycleAnalyticsDataSuccess || jest.fn().mockResolvedValue(),
      };
      return {
        mocks,
        mockDispatchContext: jest
          .fn()
          .mockImplementationOnce(mocks.requestCycleAnalyticsData)
          .mockImplementationOnce(mocks.fetchGroupStagesAndEvents)
          .mockImplementationOnce(mocks.fetchStageMedianValues)
          .mockImplementationOnce(mocks.receiveCycleAnalyticsDataSuccess),
      };
    }

    beforeEach(() => {
      state = { ...state, currentGroup, createdAfter, createdBefore };
    });

    it(`dispatches actions for required value stream analytics analytics data`, () => {
      return testAction(
        actions.fetchCycleAnalyticsData,
        state,
        null,
        [],
        [
          { type: 'requestCycleAnalyticsData' },
          { type: 'fetchValueStreams' },
          { type: 'receiveCycleAnalyticsDataSuccess' },
        ],
      );
    });

    it(`displays an error if fetchStageMedianValues fails`, () => {
      const { mockDispatchContext } = mockFetchCycleAnalyticsAction({
        fetchStageMedianValues: actions.fetchStageMedianValues({
          dispatch: jest
            .fn()
            .mockResolvedValueOnce()
            .mockImplementation(actions.receiveStageMedianValuesError({ commit: () => {} })),
          commit: () => {},
          state: { ...state },
          getters: {
            ...getters,
            activeStages,
          },
        }),
      });

      return actions
        .fetchCycleAnalyticsData({
          dispatch: mockDispatchContext,
          state: {},
          commit: () => {},
        })
        .then(() => {
          expect(createAlert).toHaveBeenCalledWith({ message: I18N_VSA_ERROR_STAGE_MEDIAN });
        });
    });

    it(`displays an error if fetchGroupStagesAndEvents fails`, () => {
      const { mockDispatchContext } = mockFetchCycleAnalyticsAction({
        fetchGroupStagesAndEvents: actions.fetchGroupStagesAndEvents({
          dispatch: jest
            .fn()
            .mockResolvedValueOnce()
            .mockImplementation(actions.receiveGroupStagesError({ commit: () => {} })),
          commit: () => {},
          state: { ...state },
          getters,
        }),
      });

      return actions
        .fetchCycleAnalyticsData({
          dispatch: mockDispatchContext,
          state: {},
          commit: () => {},
        })
        .then(() => {
          expect(createAlert).toHaveBeenCalledWith({
            message: I18N_VSA_ERROR_STAGES,
          });
        });
    });
  });

  describe('receiveCycleAnalyticsDataSuccess', () => {
    it(`commits the ${types.RECEIVE_VALUE_STREAM_DATA_SUCCESS} and dispatches the 'typeOfWork/fetchTopRankedGroupLabels' action`, () => {
      return testAction(
        actions.receiveCycleAnalyticsDataSuccess,
        null,
        state,
        [{ type: types.RECEIVE_VALUE_STREAM_DATA_SUCCESS }],
        [{ type: 'typeOfWork/fetchTopRankedGroupLabels' }],
      );
    });
  });

  describe('receiveCycleAnalyticsDataError', () => {
    it(`commits the ${types.RECEIVE_VALUE_STREAM_DATA_ERROR} mutation on a 403 response`, () => {
      const response = { status: 403 };
      return testAction(
        actions.receiveCycleAnalyticsDataError,
        { response },
        state,
        [
          {
            type: types.RECEIVE_VALUE_STREAM_DATA_ERROR,
            payload: response.status,
          },
        ],
        [],
      );
    });

    it(`commits the ${types.RECEIVE_VALUE_STREAM_DATA_ERROR} mutation on a non 403 error response`, () => {
      const response = { status: 500 };
      return testAction(
        actions.receiveCycleAnalyticsDataError,
        { response },
        state,
        [
          {
            type: types.RECEIVE_VALUE_STREAM_DATA_ERROR,
            payload: response.status,
          },
        ],
        [],
      );
    });

    it('will flash an error when the response is not 403', () => {
      const response = { status: 500 };
      actions.receiveCycleAnalyticsDataError(
        {
          commit: () => {},
        },
        { response },
      );

      expect(createAlert).toHaveBeenCalledWith({ message: flashErrorMessage });
    });
  });

  describe('initializeCycleAnalytics', () => {
    let mockDispatch;
    let mockCommit;
    let store;

    const selectedAuthor = 'Noam Chomsky';
    const selectedMilestone = '13.6';
    const selectedAssigneeList = ['nchom'];
    const selectedLabelList = ['label 1', 'label 2'];
    const initialData = {
      group: currentGroup,
      projectIds: [1, 2],
      milestonesPath,
      labelsPath,
      selectedAuthor,
      selectedMilestone,
      selectedAssigneeList,
      selectedLabelList,
    };

    beforeEach(() => {
      mockDispatch = jest.fn(() => Promise.resolve());
      mockCommit = jest.fn();
      store = {
        state,
        getters,
        commit: mockCommit,
        dispatch: mockDispatch,
      };
    });

    describe('with only group in initialData', () => {
      it('commits "INITIALIZE_VSA"', async () => {
        await actions.initializeCycleAnalytics(store, { group });
        expect(mockCommit).toHaveBeenCalledWith('INITIALIZE_VSA', { group });
      });

      it('dispatches "fetchCycleAnalyticsData" and "initializeCycleAnalyticsSuccess"', async () => {
        await actions.initializeCycleAnalytics(store, { group });
        expect(mockDispatch).toHaveBeenCalledWith('fetchCycleAnalyticsData');
      });
    });

    describe('with initialData', () => {
      it.each`
        action                        | args
        ${'setPaths'}                 | ${{ milestonesPath, labelsPath, groupPath: currentGroup.fullPath }}
        ${'filters/initialize'}       | ${{ selectedAuthor, selectedMilestone, selectedAssigneeList, selectedLabelList }}
        ${'durationChart/setLoading'} | ${true}
        ${'typeOfWork/setLoading'}    | ${true}
      `('dispatches $action', async ({ action, args }) => {
        await actions.initializeCycleAnalytics(store, initialData);

        expect(mockDispatch).toHaveBeenCalledWith(action, args);
      });

      it('dispatches "fetchCycleAnalyticsData" and "initializeCycleAnalyticsSuccess"', async () => {
        await actions.initializeCycleAnalytics(store, initialData);
        expect(mockDispatch).toHaveBeenCalledWith('fetchCycleAnalyticsData');
        expect(mockDispatch).toHaveBeenCalledWith('initializeCycleAnalyticsSuccess');
      });

      describe('with a selected stage', () => {
        it('dispatches "setSelectedStage" and "fetchStageData"', async () => {
          const stage = { id: 2, title: 'plan' };
          await actions.initializeCycleAnalytics(store, {
            ...initialData,
            stage,
          });
          expect(mockDispatch).toHaveBeenCalledWith('setSelectedStage', stage);
          expect(mockDispatch).toHaveBeenCalledWith('fetchStageData', stage.id);
        });
      });

      describe('with pagination parameters', () => {
        it('dispatches "setSelectedStage" and "fetchStageData"', async () => {
          const stage = { id: 2, title: 'plan' };
          const pagination = { sort: 'end_event', direction: 'desc', page: 1337 };
          const payload = { ...initialData, stage, pagination };
          await actions.initializeCycleAnalytics(store, payload);
          expect(mockCommit).toHaveBeenCalledWith('INITIALIZE_VSA', payload);
        });
      });

      describe('without a selected stage', () => {
        it('dispatches "setDefaultSelectedStage"', async () => {
          await actions.initializeCycleAnalytics(store, {
            ...initialData,
            stage: null,
          });
          expect(mockDispatch).not.toHaveBeenCalledWith('setSelectedStage');
          expect(mockDispatch).not.toHaveBeenCalledWith('fetchStageData');
          expect(mockDispatch).toHaveBeenCalledWith('setDefaultSelectedStage');
        });
      });

      it('commits "INITIALIZE_VSA"', async () => {
        await actions.initializeCycleAnalytics(store, initialData);
        expect(mockCommit).toHaveBeenCalledWith('INITIALIZE_VSA', initialData);
      });
    });
  });

  describe('initializeCycleAnalyticsSuccess', () => {
    it(`commits the ${types.INITIALIZE_VALUE_STREAM_SUCCESS} mutation`, () =>
      testAction(
        actions.initializeCycleAnalyticsSuccess,
        null,
        state,
        [{ type: types.INITIALIZE_VALUE_STREAM_SUCCESS }],
        [],
      ));
  });

  describe('fetchGroupLabels', () => {
    beforeEach(() => {
      mock.onGet(endpoints.groupLabels).reply(HTTP_STATUS_OK, groupLabels);
    });

    it(`will commit the "REQUEST_GROUP_LABELS" and "RECEIVE_GROUP_LABELS_SUCCESS" mutations`, () => {
      return testAction({
        action: actions.fetchGroupLabels,
        state,
        expectedMutations: [
          { type: types.REQUEST_GROUP_LABELS },
          { type: types.RECEIVE_GROUP_LABELS_SUCCESS, payload: groupLabels },
        ],
      });
    });

    describe('with a failed request', () => {
      beforeEach(() => {
        mock.onGet(endpoints.groupLabels).reply(HTTP_STATUS_BAD_REQUEST);
      });

      it(`will commit the "RECEIVE_GROUP_LABELS_ERROR" mutation`, () => {
        return testAction({
          action: actions.fetchGroupLabels,
          state,
          expectedMutations: [
            { type: types.REQUEST_GROUP_LABELS },
            { type: types.RECEIVE_GROUP_LABELS_ERROR },
          ],
        });
      });
    });
  });
});
