import MockAdapter from 'axios-mock-adapter';
import { DATE_RANGES, PRESET_TYPES, MILESTONES_GROUP } from 'ee/roadmap/constants';
import groupMilestones from 'ee/roadmap/queries/group_milestones.query.graphql';
import epicChildEpics from 'ee/roadmap/queries/epic_child_epics.query.graphql';
import * as actions from 'ee/roadmap/store/actions';
import * as types from 'ee/roadmap/store/mutation_types';
import defaultState from 'ee/roadmap/store/state';
import * as epicUtils from 'ee/roadmap/utils/epic_utils';
import * as roadmapItemUtils from 'ee/roadmap/utils/roadmap_item_utils';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';
import testAction from 'helpers/vuex_action_helper';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import {
  mockGroupId,
  basePath,
  mockTimeframeInitialDate,
  mockTimeframeMonthsAppend,
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

jest.mock('~/alert');

const mockTimeframeMonths = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.CURRENT_YEAR,
  presetType: PRESET_TYPES.MONTHS,
  initialDate: mockTimeframeInitialDate,
});

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
      filterParams: {
        milestoneTitle: '',
      },
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

    it('should show alert error', () => {
      actions.receiveEpicsFailure({ commit: () => {} });

      expect(createAlert).toHaveBeenCalledWith({
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
      beforeEach(() => {
        jest.spyOn(epicUtils.gqClient, 'query').mockReturnValue(
          Promise.resolve({
            data: mockGroupEpicsQueryResponse.data,
          }),
        );
      });

      describe.each([true, false])(
        'when the epicColorHighlight feature flag enabled is %s',
        (withColorEnabled) => {
          beforeEach(() => {
            window.gon = { features: { epicColorHighlight: withColorEnabled } };
          });

          it('calls query', async () => {
            state.epicIid = 7;
            await actions.fetchEpics({ state, commit: jest.fn(), dispatch: jest.fn() });

            expect(epicUtils.gqClient.query).toHaveBeenCalledWith({
              query: epicChildEpics,
              variables: {
                endCursor: undefined,
                fullPath: '',
                iid: state.epicIid,
                sort: state.sortedBy,
                state: state.epicsState,
                timeframe: {
                  start: '2018-01-01',
                  end: '2018-12-31',
                },
                withColor: withColorEnabled,
              },
            });
          });
        },
      );

      it('should perform REQUEST_EPICS mutation dispatch receiveEpicsSuccess action when request is successful', () => {
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

    describe('with successful child epics query response', () => {
      beforeEach(() => {
        jest.spyOn(epicUtils.gqClient, 'query').mockReturnValue(
          Promise.resolve({
            data: mockEpicChildEpicsQueryResponse.data,
          }),
        );

        state.childrenFlags[parentItem.id] = {
          itemExpanded: false,
        };
      });

      describe.each([true, false])(
        'when the epicColorHighlight feature flag enabled is %s',
        (withColorEnabled) => {
          beforeEach(() => {
            window.gon = { features: { epicColorHighlight: withColorEnabled } };
          });

          it('should query children epics', async () => {
            await actions.toggleEpic({ state, dispatch: jest.fn() }, { parentItem });

            expect(epicUtils.gqClient.query).toHaveBeenCalledWith({
              query: epicChildEpics,
              variables: {
                fullPath: '/groups/gitlab-org/',
                iid: parentItem.iid,
                sort: state.sortedBy,
                state: state.epicsState,
                withColor: withColorEnabled,
                milestoneTitle: '',
              },
            });
          });
        },
      );

      it('should dispatch `receiveChildrenSuccess`', async () => {
        await testAction(
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
        milestonesState: 'active',
        presetType: PRESET_TYPES.MONTHS,
        timeframe: mockTimeframeMonths,
        filterParams: {
          milestoneTitle: '',
        },
      };

      expectedVariables = {
        fullPath: 'gitlab-org',
        state: mockState.milestonesState,
        timeframe: {
          start: '2018-01-01',
          end: '2018-12-31',
        },
        includeDescendants: true,
        includeAncestors: true,
        searchTitle: '',
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

    it('should fetch searched Group Milestones using GraphQL client', async () => {
      mockState.filterParams = {
        milestoneTitle: mockGroupMilestones[0].title,
      };

      expectedVariables.searchTitle = mockGroupMilestones[0].title;

      jest.spyOn(epicUtils.gqClient, 'query').mockReturnValue(
        Promise.resolve({
          data: mockGroupMilestonesQueryResponse.data,
        }),
      );

      await actions.fetchGroupMilestones(mockState);
      expect(epicUtils.gqClient.query).toHaveBeenCalledWith({
        query: groupMilestones,
        variables: expectedVariables,
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
                startDateOutOfRange: true,
                endDateOutOfRange: false,
                startDate: new Date(2018, 0, 1),
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

    it('should show alert error', () => {
      actions.receiveMilestonesFailure({ commit: () => {} });

      expect(createAlert).toHaveBeenCalledWith({
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

  describe('setDaterange', () => {
    it('should set epicsState in store state', () => {
      return testAction(
        actions.setDaterange,
        { timeframeRangeType: 'CURRENT_YEAR', presetType: 'MONTHS' },
        state,
        [
          {
            type: types.SET_DATERANGE,
            payload: { timeframeRangeType: 'CURRENT_YEAR', presetType: 'MONTHS' },
          },
        ],
      );
    });
  });

  describe('setProgressTracking', () => {
    it('should set progressTracking in store state', () => {
      return testAction(
        actions.setProgressTracking,
        'COUNT',
        state,
        [{ type: types.SET_PROGRESS_TRACKING, payload: 'COUNT' }],
        [],
      );
    });
  });

  describe('toggleProgressTrackingActive', () => {
    it('commit TOGGLE_PROGRESS_TRACKING_ACTIVE mutation', () => {
      return testAction(
        actions.toggleProgressTrackingActive,
        undefined,
        state,
        [{ type: types.TOGGLE_PROGRESS_TRACKING_ACTIVE }],
        [],
      );
    });
  });

  describe('setMilestonesType', () => {
    it('should set milestonesType in store state', () => {
      return testAction(
        actions.setMilestonesType,
        MILESTONES_GROUP,
        state,
        [{ type: types.SET_MILESTONES_TYPE, payload: MILESTONES_GROUP }],
        [],
      );
    });
  });

  describe('toggleMilestones', () => {
    it('commit TOGGLE_MILESTONES mutation', () => {
      return testAction(
        actions.toggleMilestones,
        undefined,
        state,
        [{ type: types.TOGGLE_MILESTONES }],
        [],
      );
    });
  });

  describe('toggleLabels', () => {
    it('commit TOGGLE_LABELS mutation', () => {
      return testAction(
        actions.toggleLabels,
        undefined,
        state,
        [{ type: types.TOGGLE_LABELS }],
        [],
      );
    });
  });
});
