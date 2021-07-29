import MockAdapter from 'axios-mock-adapter';
import { PRESET_TYPES, EXTEND_AS } from 'ee/roadmap/constants';
import groupMilestones from 'ee/roadmap/queries/groupMilestones.query.graphql';
import * as actions from 'ee/roadmap/store/actions';
import * as types from 'ee/roadmap/store/mutation_types';
import defaultState from 'ee/roadmap/store/state';
import * as epicUtils from 'ee/roadmap/utils/epic_utils';
import * as roadmapItemUtils from 'ee/roadmap/utils/roadmap_item_utils';
import { getTimeframeForMonthsView } from 'ee/roadmap/utils/roadmap_utils';
import testAction from 'helpers/vuex_action_helper';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import {
  mockGroupId,
  basePath,
  mockTimeframeInitialDate,
  mockTimeframeMonthsPrepend,
  mockTimeframeMonthsAppend,
  rawEpics,
  mockRawEpic,
  mockRawEpic2,
  mockFormattedEpic,
  mockFormattedEpic2,
  mockSortedBy,
  mockGroupEpicsQueryResponse,
  mockGroupEpics,
  mockEpicChildEpicsQueryResponse,
  mockChildEpicNode1,
  mockGroupMilestonesQueryResponse,
  mockGroupMilestones,
  mockMilestone,
  mockFormattedMilestone,
  mockPageInfo,
} from '../mock_data';

jest.mock('~/flash');

const mockTimeframeMonths = getTimeframeForMonthsView(mockTimeframeInitialDate);

describe('Roadmap Vuex Actions', () => {
  const timeframeStartDate = mockTimeframeMonths[0];
  const timeframeEndDate = mockTimeframeMonths[mockTimeframeMonths.length - 1];
  let state;

  beforeEach(() => {
    state = {
      ...defaultState(),
      groupId: mockGroupId,
      timeframe: mockTimeframeMonths,
      presetType: PRESET_TYPES.MONTHS,
      sortedBy: mockSortedBy,
      filterQueryString: '',
      basePath,
      timeframeStartDate,
      timeframeEndDate,
    };
  });

  describe('setInitialData', () => {
    it('should set initial roadmap props', () => {
      const mockRoadmap = {
        foo: 'bar',
        bar: 'baz',
      };

      return testAction(
        actions.setInitialData,
        mockRoadmap,
        {},
        [{ type: types.SET_INITIAL_DATA, payload: mockRoadmap }],
        [],
      );
    });
  });

  describe('receiveEpicsSuccess', () => {
    it('should set formatted epics array and epicId to IDs array in state based on provided epics list', () => {
      return testAction(
        actions.receiveEpicsSuccess,
        {
          rawEpics: [mockRawEpic2],
          pageInfo: mockPageInfo,
        },
        state,
        [
          {
            type: types.UPDATE_EPIC_IDS,
            payload: [mockRawEpic2.id],
          },
          {
            type: types.RECEIVE_EPICS_SUCCESS,
            payload: { epics: [mockFormattedEpic2], pageInfo: mockPageInfo },
          },
        ],
        [
          {
            type: 'initItemChildrenFlags',
            payload: {
              epics: [mockFormattedEpic2],
            },
          },
        ],
      );
    });

    it('should set formatted epics array and epicId to IDs array in state based on provided epics list when timeframe was extended', () => {
      return testAction(
        actions.receiveEpicsSuccess,
        {
          rawEpics: [mockRawEpic],
          newEpic: true,
          timeframeExtended: true,
        },
        state,
        [
          { type: types.UPDATE_EPIC_IDS, payload: [mockRawEpic.id] },
          {
            type: types.RECEIVE_EPICS_FOR_TIMEFRAME_SUCCESS,
            payload: [{ ...mockFormattedEpic, newEpic: true }],
          },
        ],
        [
          {
            type: 'initItemChildrenFlags',
            payload: {
              epics: [
                {
                  ...mockFormattedEpic,
                  newEpic: true,
                  startDateOutOfRange: true,
                  endDateOutOfRange: false,
                },
              ],
            },
          },
        ],
      );
    });
  });

  describe('receiveEpicsFailure', () => {
    it('should set epicsFetchInProgress, epicsFetchForTimeframeInProgress to false and epicsFetchFailure to true', () => {
      return testAction(
        actions.receiveEpicsFailure,
        {},
        state,
        [{ type: types.RECEIVE_EPICS_FAILURE }],
        [],
      );
    });

    it('should show flash error', () => {
      actions.receiveEpicsFailure({ commit: () => {} });

      expect(createFlash).toHaveBeenCalledWith({
        message: 'Something went wrong while fetching epics',
      });
    });
  });

  describe('fetchEpics', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('success', () => {
      it('should perform REQUEST_EPICS mutation dispatch receiveEpicsSuccess action when request is successful', () => {
        jest.spyOn(epicUtils.gqClient, 'query').mockReturnValue(
          Promise.resolve({
            data: mockGroupEpicsQueryResponse.data,
          }),
        );

        return testAction(
          actions.fetchEpics,
          {},
          state,
          [
            {
              type: types.REQUEST_EPICS,
            },
          ],
          [
            {
              type: 'receiveEpicsSuccess',
              payload: { rawEpics: mockGroupEpics, pageInfo: mockPageInfo, appendToList: false },
            },
          ],
        );
      });
    });

    describe('failure', () => {
      it('should perform REQUEST_EPICS mutation and dispatch receiveEpicsFailure action when request fails', () => {
        jest.spyOn(epicUtils.gqClient, 'query').mockRejectedValue(new Error('error message'));

        return testAction(
          actions.fetchEpics,
          {},
          state,
          [
            {
              type: types.REQUEST_EPICS,
            },
          ],
          [
            {
              type: 'receiveEpicsFailure',
            },
          ],
        );
      });
    });
  });

  describe('fetchEpicsForTimeframe', () => {
    describe('success', () => {
      it('should perform REQUEST_EPICS_FOR_TIMEFRAME mutation and dispatch receiveEpicsSuccess action when request is successful', () => {
        jest.spyOn(epicUtils.gqClient, 'query').mockReturnValue(
          Promise.resolve({
            data: mockGroupEpicsQueryResponse.data,
          }),
        );

        return testAction(
          actions.fetchEpicsForTimeframe,
          { timeframe: mockTimeframeMonths },
          state,
          [
            {
              type: types.REQUEST_EPICS_FOR_TIMEFRAME,
            },
          ],
          [
            {
              type: 'receiveEpicsSuccess',
              payload: {
                rawEpics: mockGroupEpics,
                pageInfo: mockPageInfo,
                newEpic: true,
                timeframeExtended: true,
              },
            },
          ],
        );
      });
    });

    describe('failure', () => {
      it('should perform REQUEST_EPICS_FOR_TIMEFRAME mutation and dispatch requestEpicsFailure action when request fails', () => {
        jest.spyOn(epicUtils.gqClient, 'query').mockRejectedValue();

        return testAction(
          actions.fetchEpicsForTimeframe,
          { timeframe: mockTimeframeMonths },
          state,
          [
            {
              type: types.REQUEST_EPICS_FOR_TIMEFRAME,
            },
          ],
          [
            {
              type: 'receiveEpicsFailure',
            },
          ],
        );
      });
    });
  });

  describe('extendTimeframe', () => {
    it('should prepend to timeframe when called with extend type prepend', () => {
      return testAction(
        actions.extendTimeframe,
        { extendAs: EXTEND_AS.PREPEND },
        state,
        [{ type: types.PREPEND_TIMEFRAME, payload: mockTimeframeMonthsPrepend }],
        [],
      );
    });

    it('should append to timeframe when called with extend type append', () => {
      return testAction(
        actions.extendTimeframe,
        { extendAs: EXTEND_AS.APPEND },
        state,
        [{ type: types.APPEND_TIMEFRAME, payload: mockTimeframeMonthsAppend }],
        [],
      );
    });
  });

  describe('refreshEpicDates', () => {
    it('should update epics after refreshing epic dates to match with updated timeframe', () => {
      const epics = rawEpics.map((epic) =>
        roadmapItemUtils.formatRoadmapItemDetails(
          epic,
          state.timeframeStartDate,
          state.timeframeEndDate,
        ),
      );

      return testAction(
        actions.refreshEpicDates,
        {},
        { ...state, timeframe: mockTimeframeMonths.concat(mockTimeframeMonthsAppend), epics },
        [{ type: types.SET_EPICS, payload: epics }],
        [],
      );
    });
  });

  describe('requestChildrenEpics', () => {
    const parentItemId = '41';
    it('should set `itemChildrenFetchInProgress` in childrenFlags for parentItem to true', () => {
      return testAction(
        actions.requestChildrenEpics,
        { parentItemId },
        state,
        [{ type: 'REQUEST_CHILDREN_EPICS', payload: { parentItemId } }],
        [],
      );
    });
  });

  describe('receiveChildrenSuccess', () => {
    it('should set formatted epic children array in state based on provided epic children list', () => {
      return testAction(
        actions.receiveChildrenSuccess,
        {
          parentItemId: '41',
          rawChildren: [mockRawEpic2],
        },
        state,
        [
          {
            type: types.RECEIVE_CHILDREN_SUCCESS,
            payload: {
              parentItemId: '41',
              children: [
                {
                  ...mockFormattedEpic2,
                  isChildEpic: true,
                },
              ],
            },
          },
        ],
        [
          {
            type: 'expandEpic',
            payload: { parentItemId: '41' },
          },
          {
            type: 'initItemChildrenFlags',
            payload: {
              epics: [
                {
                  ...mockFormattedEpic2,
                  isChildEpic: true,
                },
              ],
            },
          },
        ],
      );
    });
  });

  describe('initItemChildrenFlags', () => {
    it('should set `state.childrenFlags` for every item in provided children param', () => {
      testAction(
        actions.initItemChildrenFlags,
        { children: [{ id: '1' }] },
        {},
        [{ type: types.INIT_EPIC_CHILDREN_FLAGS, payload: { children: [{ id: '1' }] } }],
        [],
      );
    });
  });

  describe('expandEpic', () => {
    const parentItemId = '41';
    it('should set `itemExpanded` to true on state.childrenFlags', () => {
      testAction(
        actions.expandEpic,
        { parentItemId },
        {},
        [{ type: types.EXPAND_EPIC, payload: { parentItemId } }],
        [],
      );
    });
  });

  describe('collapseEpic', () => {
    const parentItemId = '41';
    it('should set `itemExpanded` to false on state.childrenFlags', () => {
      testAction(
        actions.collapseEpic,
        { parentItemId },
        {},
        [{ type: types.COLLAPSE_EPIC, payload: { parentItemId } }],
        [],
      );
    });
  });

  describe('toggleEpic', () => {
    const parentItem = mockFormattedEpic;

    it('should dispatch `requestChildrenEpics` action when parent is not expanded and does not have children in state', () => {
      state.childrenFlags[parentItem.id] = {
        itemExpanded: false,
      };

      testAction(
        actions.toggleEpic,
        { parentItem },
        state,
        [],
        [
          {
            type: 'requestChildrenEpics',
            payload: { parentItemId: parentItem.id },
          },
        ],
      );
    });

    it('should dispatch `receiveChildrenSuccess` on request success', () => {
      jest.spyOn(epicUtils.gqClient, 'query').mockReturnValue(
        Promise.resolve({
          data: mockEpicChildEpicsQueryResponse.data,
        }),
      );

      state.childrenFlags[parentItem.id] = {
        itemExpanded: false,
      };

      testAction(
        actions.toggleEpic,
        { parentItem },
        state,
        [],
        [
          {
            type: 'requestChildrenEpics',
            payload: { parentItemId: parentItem.id },
          },
          {
            type: 'receiveChildrenSuccess',
            payload: {
              parentItemId: parentItem.id,
              rawChildren: [mockChildEpicNode1],
            },
          },
        ],
      );
    });

    it('should dispatch `receiveEpicsFailure` on request failure', () => {
      jest.spyOn(epicUtils.gqClient, 'query').mockReturnValue(Promise.reject());

      state.childrenFlags[parentItem.id] = {
        itemExpanded: false,
      };

      testAction(
        actions.toggleEpic,
        { parentItem },
        state,
        [],
        [
          {
            type: 'requestChildrenEpics',
            payload: { parentItemId: parentItem.id },
          },
          {
            type: 'receiveEpicsFailure',
          },
        ],
      );
    });

    it('should dispatch `expandEpic` when a parent item is not expanded but does have children present in state', () => {
      state.childrenFlags[parentItem.id] = {
        itemExpanded: false,
      };
      state.childrenEpics[parentItem.id] = ['foo'];

      testAction(
        actions.toggleEpic,
        { parentItem },
        state,
        [],
        [
          {
            type: 'expandEpic',
            payload: { parentItemId: parentItem.id },
          },
        ],
      );
    });

    it('should dispatch `collapseEpic` when a parent item is expanded', () => {
      state.childrenFlags[parentItem.id] = {
        itemExpanded: true,
      };

      testAction(
        actions.toggleEpic,
        { parentItem },
        state,
        [],
        [
          {
            type: 'collapseEpic',
            payload: { parentItemId: parentItem.id },
          },
        ],
      );
    });
  });

  describe('setBufferSize', () => {
    it('should set bufferSize in store state', () => {
      return testAction(
        actions.setBufferSize,
        10,
        state,
        [{ type: types.SET_BUFFER_SIZE, payload: 10 }],
        [],
      );
    });
  });

  describe('fetchGroupMilestones', () => {
    let mockState;
    let expectedVariables;

    beforeEach(() => {
      mockState = {
        fullPath: 'gitlab-org',
        milestonessState: 'active',
        presetType: PRESET_TYPES.MONTHS,
        timeframe: mockTimeframeMonths,
      };

      expectedVariables = {
        fullPath: 'gitlab-org',
        state: mockState.milestonessState,
        timeframe: {
          start: '2017-11-01',
          end: '2018-06-30',
        },
        includeDescendants: true,
      };
    });

    it('should fetch Group Milestones using GraphQL client when milestoneIid is not present in state', () => {
      jest.spyOn(epicUtils.gqClient, 'query').mockReturnValue(
        Promise.resolve({
          data: mockGroupMilestonesQueryResponse.data,
        }),
      );

      return actions.fetchGroupMilestones(mockState).then(() => {
        expect(epicUtils.gqClient.query).toHaveBeenCalledWith({
          query: groupMilestones,
          variables: expectedVariables,
        });
      });
    });
  });

  describe('requestMilestones', () => {
    it('should set `milestonesFetchInProgress` to true', () => {
      return testAction(actions.requestMilestones, {}, state, [{ type: 'REQUEST_MILESTONES' }], []);
    });
  });

  describe('fetchMilestones', () => {
    describe('success', () => {
      it('should dispatch requestMilestones and receiveMilestonesSuccess when request is successful', () => {
        jest.spyOn(epicUtils.gqClient, 'query').mockReturnValue(
          Promise.resolve({
            data: mockGroupMilestonesQueryResponse.data,
          }),
        );

        return testAction(
          actions.fetchMilestones,
          null,
          state,
          [],
          [
            {
              type: 'requestMilestones',
            },
            {
              type: 'receiveMilestonesSuccess',
              payload: { rawMilestones: mockGroupMilestones },
            },
          ],
        );
      });
    });

    describe('failure', () => {
      it('should dispatch requestMilestones and receiveMilestonesFailure when request fails', () => {
        jest.spyOn(epicUtils.gqClient, 'query').mockReturnValue(Promise.reject());

        return testAction(
          actions.fetchMilestones,
          null,
          state,
          [],
          [
            {
              type: 'requestMilestones',
            },
            {
              type: 'receiveMilestonesFailure',
            },
          ],
        );
      });
    });
  });

  describe('receiveMilestonesSuccess', () => {
    it('should set formatted milestones array and milestoneId to IDs array in state based on provided milestones list', () => {
      return testAction(
        actions.receiveMilestonesSuccess,
        {
          rawMilestones: [{ ...mockMilestone, start_date: '2017-12-31', end_date: '2018-2-15' }],
        },
        state,
        [
          { type: types.UPDATE_MILESTONE_IDS, payload: [mockMilestone.id] },
          {
            type: types.RECEIVE_MILESTONES_SUCCESS,
            payload: [
              {
                ...mockFormattedMilestone,
                startDateOutOfRange: false,
                endDateOutOfRange: false,
                startDate: new Date(2017, 11, 31),
                originalStartDate: new Date(2017, 11, 31),
                endDate: new Date(2018, 1, 15),
                originalEndDate: new Date(2018, 1, 15),
              },
            ],
          },
        ],
        [],
      );
    });
  });

  describe('receiveMilestonesFailure', () => {
    it('should set milestonesFetchInProgress to false and milestonesFetchFailure to true', () => {
      return testAction(
        actions.receiveMilestonesFailure,
        {},
        state,
        [{ type: types.RECEIVE_MILESTONES_FAILURE }],
        [],
      );
    });

    it('should show flash error', () => {
      actions.receiveMilestonesFailure({ commit: () => {} });

      expect(createFlash).toHaveBeenCalledWith({
        message: 'Something went wrong while fetching milestones',
      });
    });
  });

  describe('refreshMilestoneDates', () => {
    it('should update milestones after refreshing milestone dates to match with updated timeframe', () => {
      const milestones = mockGroupMilestones.map((milestone) =>
        roadmapItemUtils.formatRoadmapItemDetails(
          milestone,
          state.timeframeStartDate,
          state.timeframeEndDate,
        ),
      );

      return testAction(
        actions.refreshMilestoneDates,
        {},
        { ...state, timeframe: mockTimeframeMonths.concat(mockTimeframeMonthsAppend), milestones },
        [{ type: types.SET_MILESTONES, payload: milestones }],
        [],
      );
    });
  });
});
