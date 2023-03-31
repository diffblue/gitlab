import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import * as actions from 'ee/analytics/cycle_analytics/store/actions';
import * as getters from 'ee/analytics/cycle_analytics/store/getters';
import * as types from 'ee/analytics/cycle_analytics/store/mutation_types';
import testAction from 'helpers/vuex_action_helper';
import {
  createdAfter,
  createdBefore,
  groupNamespace as namespace,
  projectNamespace,
  currentGroup,
} from 'jest/analytics/cycle_analytics/mock_data';
import {
  I18N_VSA_ERROR_STAGES,
  I18N_VSA_ERROR_STAGE_MEDIAN,
} from '~/analytics/cycle_analytics/constants';
import { createAlert } from '~/alert';
import {
  HTTP_STATUS_BAD_REQUEST,
  HTTP_STATUS_FORBIDDEN,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_OK,
} from '~/lib/utils/http_status';
import { allowedStages as stages, valueStreams, endpoints, groupLabels } from '../mock_data';

const milestonesPath = `/${namespace.fullPath}/-/milestones.json`;
const labelsPath = `/${namespace.fullPath}/-/labels.json`;
const groupEndpoint = 'groups/foo';

const alertErrorMessage = 'There was an error while fetching value stream analytics data.';

stages[0].hidden = true;
const activeStages = stages.filter(({ hidden }) => !hidden);
const [selectedValueStream] = valueStreams;

const defaultState = {
  createdAfter,
  createdBefore,
  stages: [],
  features: {},
  activeStages,
  selectedValueStream,
  groupPath: currentGroup.fullPath,
  enableTasksByTypeChart: true,
};

const mockGetters = {
  namespacePath: () => namespace.fullPath,
  currentValueStreamId: () => selectedValueStream.id,
};

jest.mock('~/alert');

describe('Value Stream Analytics actions', () => {
  let state;
  let mock;

  beforeEach(() => {
    state = {
      ...defaultState,
      ...mockGetters,
    };
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
    state = { ...state, namespace: null };
  });

  it.each`
    action           | type              | stateKey      | payload
    ${'setFeatures'} | ${'SET_FEATURES'} | ${'features'} | ${{ someFeatureFlag: true }}
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

  describe('with a project namespace', () => {
    it('setPaths dispatches the filters/setEndpoints action with project endpoints', () => {
      return testAction(
        actions.setPaths,
        {},
        { ...state, namespace: projectNamespace, isProjectNamespace: true },
        [],
        [
          {
            type: 'filters/setEndpoints',
            payload: {
              groupEndpoint,
              labelsEndpoint: '/some/cool/path/-/labels.json',
              milestonesEndpoint: '/some/cool/path/-/milestones.json',
              projectEndpoint: 'some/cool/path',
            },
          },
        ],
      );
    });
  });

  describe('setPaths', () => {
    it('dispatches the filters/setEndpoints action with endpoints', () => {
      return testAction(
        actions.setPaths,
        {},
        { ...state, namespace },
        [],
        [
          {
            type: 'filters/setEndpoints',
            payload: {
              groupEndpoint,
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
      // TODO: It seems like we have been missing failure test cases for these API requests
      //       this should be addressed as part of https://gitlab.com/gitlab-org/gitlab/-/issues/396665
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
      state = { ...state, namespace, createdAfter, createdBefore };
    });

    it(`dispatches actions for required value stream analytics analytics data`, () => {
      return testAction(
        actions.fetchCycleAnalyticsData,
        state,
        getters,
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

    it(`with 'enableTasksByTypeChart=false' does not dispatch the 'typeOfWork/fetchTopRankedGroupLabels' action`, () => {
      return testAction(
        actions.receiveCycleAnalyticsDataSuccess,
        null,
        { ...state, enableTasksByTypeChart: false },
        [{ type: types.RECEIVE_VALUE_STREAM_DATA_SUCCESS }],
      );
    });
  });

  describe('receiveCycleAnalyticsDataError', () => {
    it(`commits the ${types.RECEIVE_VALUE_STREAM_DATA_ERROR} mutation on a 403 response`, () => {
      const response = { status: HTTP_STATUS_FORBIDDEN };
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
      const response = { status: HTTP_STATUS_INTERNAL_SERVER_ERROR };
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

    it('will alert an error when the response is not 403', () => {
      const response = { status: HTTP_STATUS_INTERNAL_SERVER_ERROR };
      actions.receiveCycleAnalyticsDataError(
        {
          commit: () => {},
        },
        { response },
      );

      expect(createAlert).toHaveBeenCalledWith({ message: alertErrorMessage });
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
      namespace,
      projectIds: [1, 2],
      milestonesPath,
      labelsPath,
      selectedAuthor,
      selectedMilestone,
      selectedAssigneeList,
      selectedLabelList,
      enableTasksByTypeChart: true,
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

    describe('with only namespace in initialData', () => {
      it('commits "INITIALIZE_VSA"', async () => {
        await actions.initializeCycleAnalytics(store, { namespace });
        expect(mockCommit).toHaveBeenCalledWith('INITIALIZE_VSA', { namespace });
      });

      it('dispatches "fetchCycleAnalyticsData" and "initializeCycleAnalyticsSuccess"', async () => {
        await actions.initializeCycleAnalytics(store, { namespace });
        expect(mockDispatch).toHaveBeenCalledWith('fetchCycleAnalyticsData');
      });
    });

    describe('with initialData', () => {
      it.each`
        action                        | args
        ${'setPaths'}                 | ${{ namespacePath: namespace.fullPath }}
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

      describe('with `enableTasksByTypeChart=false`', () => {
        it.each`
          action                        | args
          ${'setPaths'}                 | ${{ namespacePath: namespace.fullPath }}
          ${'filters/initialize'}       | ${{ selectedAuthor, selectedMilestone, selectedAssigneeList, selectedLabelList }}
          ${'durationChart/setLoading'} | ${true}
        `('dispatches $action', async ({ action, args }) => {
          await actions.initializeCycleAnalytics(store, {
            ...initialData,
            enableTasksByTypeChart: false,
          });

          expect(mockDispatch).toHaveBeenCalledWith(action, args);
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
