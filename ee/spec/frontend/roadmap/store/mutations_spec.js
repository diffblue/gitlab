import * as types from 'ee/roadmap/store/mutation_types';
import mutations from 'ee/roadmap/store/mutations';

import { PROGRESS_COUNT, MILESTONES_GROUP } from 'ee/roadmap/constants';
import defaultState from 'ee/roadmap/store/state';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';

import {
  mockGroupId,
  basePath,
  mockSortedBy,
  mockEpic,
  mockPageInfo,
} from 'ee_jest/roadmap/mock_data';

const setEpicMockData = (state) => {
  state.epics = [mockEpic];
  state.childrenFlags = { 'gid://gitlab/Epic/1': {} };
  state.epicIds = ['gid://gitlab/Epic/1'];
};

describe('Roadmap Store Mutations', () => {
  let state;

  beforeEach(() => {
    state = defaultState();
  });

  describe('SET_INITIAL_DATA', () => {
    it('Should set initial Roadmap data to state', () => {
      const initialData = {
        epicsFetchInProgress: false,
        epicsFetchForTimeframeInProgress: false,
        epicsFetchFailure: false,
        epicsFetchResultEmpty: false,
        currentGroupId: mockGroupId,
        sortedBy: mockSortedBy,
        defaultInnerHeight: 600,
        extendedTimeframe: [],
        filterQueryString: '',
        epicsState: 'all',
        epicIds: [],
        epics: [],
        basePath,
      };

      mutations[types.SET_INITIAL_DATA](state, initialData);

      expect(state).toEqual(expect.objectContaining(initialData));
    });
  });

  describe('SET_EPICS', () => {
    it('Should provided epics array in state', () => {
      const epics = [{ id: 1 }, { id: 2 }];

      mutations[types.SET_EPICS](state, epics);

      expect(state.epics).toEqual(epics);
    });
  });

  describe('UPDATE_EPIC_IDS', () => {
    it('Should insert provided epicId to epicIds array in state', () => {
      mutations[types.UPDATE_EPIC_IDS](state, [22]);

      expect(state.epicIds).toHaveLength(1);
      expect(state.epicIds[0]).toBe(22);
    });
  });

  describe('REQUEST_EPICS', () => {
    it('Should set state.epicsFetchInProgress to `true`', () => {
      mutations[types.REQUEST_EPICS](state);

      expect(state.epicsFetchInProgress).toBe(true);
    });
  });

  describe('REQUEST_EPICS_FOR_TIMEFRAME', () => {
    it('Should set state.epicsFetchForTimeframeInProgress to `true`', () => {
      mutations[types.REQUEST_EPICS_FOR_TIMEFRAME](state);

      expect(state.epicsFetchForTimeframeInProgress).toBe(true);
    });
  });

  describe('REQUEST_EPICS_FOR_NEXT_PAGE', () => {
    it('Should set state.epicsFetchForNextPageInProgress to `true`', () => {
      mutations[types.REQUEST_EPICS_FOR_NEXT_PAGE](state);

      expect(state.epicsFetchForNextPageInProgress).toBe(true);
    });
  });

  describe('RECEIVE_EPICS_SUCCESS', () => {
    it('Should set epicsFetchResultEmpty, epics in state based on provided epics array and set epicsFetchInProgress to `false`', () => {
      const epics = [{ id: 1 }, { id: 2 }];

      mutations[types.RECEIVE_EPICS_SUCCESS](state, { epics, pageInfo: mockPageInfo });

      expect(state.epicsFetchResultEmpty).toBe(false);
      expect(state.epics).toEqual(epics);
      expect(state.pageInfo).toEqual(mockPageInfo);
      expect(state.epicsFetchInProgress).toBe(false);
    });
  });

  describe('RECEIVE_EPICS_FOR_TIMEFRAME_SUCCESS', () => {
    it('Should set epics in state based on provided epics array and set epicsFetchForTimeframeInProgress to `false`', () => {
      const epics = [{ id: 1 }, { id: 2 }];

      mutations[types.RECEIVE_EPICS_FOR_TIMEFRAME_SUCCESS](state, epics);

      expect(state.epics).toEqual(epics);
      expect(state.epicsFetchForTimeframeInProgress).toBe(false);
    });
  });

  describe('RECEIVE_EPICS_FOR_NEXT_PAGE_SUCCESS', () => {
    it('Should set epics in state based on provided epics array and set epicsFetchForNextPageInProgress to `false`', () => {
      const epics = [{ id: 1 }, { id: 2 }];

      mutations[types.RECEIVE_EPICS_FOR_NEXT_PAGE_SUCCESS](state, {
        epics,
        pageInfo: mockPageInfo,
      });

      expect(state.epics).toEqual(epics);
      expect(state.pageInfo).toEqual(mockPageInfo);
      expect(state.epicsFetchForNextPageInProgress).toBe(false);
    });
  });

  describe('RECEIVE_EPICS_FAILURE', () => {
    it('Should set epicsFetchInProgress & epicsFetchForTimeframeInProgress to false and epicsFetchFailure to true', () => {
      mutations[types.RECEIVE_EPICS_FAILURE](state);

      expect(state.epicsFetchInProgress).toBe(false);
      expect(state.epicsFetchForTimeframeInProgress).toBe(false);
      expect(state.epicsFetchForNextPageInProgress).toBe(false);
      expect(state.epicsFetchFailure).toBe(true);
    });
  });

  describe('REQUEST_CHILDREN_EPICS', () => {
    const parentItemId = '1';

    it('should set `itemChildrenFetchInProgress` to true for provided `parentItem` param within state.childrenFlags', () => {
      state.childrenFlags[parentItemId] = {};
      mutations[types.REQUEST_CHILDREN_EPICS](state, { parentItemId });

      expect(state.childrenFlags[parentItemId]).toHaveProperty('itemChildrenFetchInProgress', true);
    });
  });

  describe('RECEIVE_CHILDREN_SUCCESS', () => {
    const parentItemId = '1';
    const children = [{ id: 1 }, { id: 2 }];

    it('should set provided `children` and `itemChildrenFetchInProgress` to false for provided `parentItem` param within state.childrenFlags', () => {
      state.childrenFlags[parentItemId] = {};
      mutations[types.RECEIVE_CHILDREN_SUCCESS](state, { parentItemId, children });

      expect(state.childrenEpics[parentItemId]).toEqual(children);
      expect(state.childrenFlags[parentItemId]).toHaveProperty(
        'itemChildrenFetchInProgress',
        false,
      );
    });
  });

  describe('INIT_EPIC_CHILDREN_FLAGS', () => {
    it('should set flags in `state.childrenFlags` for each epic', () => {
      const epics = [
        {
          id: '1',
        },
        {
          id: '2',
        },
      ];

      mutations[types.INIT_EPIC_CHILDREN_FLAGS](state, { epics });

      epics.forEach((item) => {
        expect(state.childrenFlags[item.id]).toMatchObject({
          itemExpanded: false,
          itemChildrenFetchInProgress: false,
        });
      });
    });
  });

  describe('EXPAND_EPIC', () => {
    it('should toggle collapsed epic to an expanded epic', () => {
      const parentItemId = '1';
      state.childrenFlags[parentItemId] = {};

      mutations[types.EXPAND_EPIC](state, { parentItemId });

      expect(state.childrenFlags[parentItemId]).toHaveProperty('itemExpanded', true);
    });
  });

  describe('COLLAPSE_EPIC', () => {
    it('should toggle expanded epic to a collapsed epic', () => {
      const parentItemId = '2';
      state.childrenFlags[parentItemId] = {};

      mutations[types.COLLAPSE_EPIC](state, { parentItemId });

      expect(state.childrenFlags[parentItemId]).toHaveProperty('itemExpanded', false);
    });
  });

  describe('SET_MILESTONES', () => {
    it('Should provided milestones array in state', () => {
      const milestones = [{ id: 1 }, { id: 2 }];

      mutations[types.SET_MILESTONES](state, milestones);

      expect(state.milestones).toEqual(milestones);
    });
  });

  describe('UPDATE_MILESTONE_IDS', () => {
    it('Should update milestoneIds array', () => {
      mutations[types.UPDATE_MILESTONE_IDS](state, [22]);

      expect(state.milestoneIds).toHaveLength(1);
      expect(state.milestoneIds[0]).toBe(22);
    });
  });

  describe('REQUEST_MILESTONES', () => {
    it('Should set state.milestonesFetchInProgress to `true`', () => {
      mutations[types.REQUEST_MILESTONES](state);

      expect(state.milestonesFetchInProgress).toBe(true);
    });
  });

  describe('RECEIVE_MILESTONES_SUCCESS', () => {
    it('Should set milestonesFetchResultEmpty, milestones in state based on provided milestones array and set milestonesFetchInProgress to `false`', () => {
      const milestones = [{ id: 1 }, { id: 2 }];

      mutations[types.RECEIVE_MILESTONES_SUCCESS](state, milestones);

      expect(state.milestonesFetchResultEmpty).toBe(false);
      expect(state.milestones).toEqual(milestones);
      expect(state.milestonesFetchInProgress).toBe(false);
    });
  });

  describe('RECEIVE_MILESTONES_FAILURE', () => {
    it('Should set milestonesFetchInProgress to false and milestonesFetchFailure to true', () => {
      mutations[types.RECEIVE_MILESTONES_FAILURE](state);

      expect(state.milestonesFetchInProgress).toBe(false);
      expect(state.milestonesFetchFailure).toBe(true);
    });
  });

  describe('SET_BUFFER_SIZE', () => {
    it('Should set `bufferSize` in state', () => {
      const bufferSize = 10;

      mutations[types.SET_BUFFER_SIZE](state, bufferSize);

      expect(state.bufferSize).toBe(bufferSize);
    });
  });

  describe('SET_FILTER_PARAMS', () => {
    it('Should set `filterParams` and `hasFiltersApplied` to the state and reset existing epics', () => {
      const filterParams = [{ foo: 'bar' }, { bar: 'baz' }];
      setEpicMockData(state);

      mutations[types.SET_FILTER_PARAMS](state, filterParams);

      expect(state).toMatchObject({
        filterParams,
        hasFiltersApplied: true,
        epics: [],
        childrenFlags: {},
        epicIds: [],
      });
    });
  });

  describe('SET_EPICS_STATE', () => {
    it('Should set `epicsState` to the state and reset existing epics', () => {
      const epicsState = 'all';
      setEpicMockData(state);

      mutations[types.SET_EPICS_STATE](state, epicsState);

      expect(state).toMatchObject({
        epicsState,
        epics: [],
        childrenFlags: {},
        epicIds: [],
      });
    });
  });

  describe('SET_DATERANGE', () => {
    it('Should set `timeframeRangeType`, `presetType` and `timeframe` to the state and reset existing epics', () => {
      const timeframeRangeType = 'CURRENT_YEAR';
      const presetType = 'MONTHS';
      setEpicMockData(state);

      mutations[types.SET_DATERANGE](state, { timeframeRangeType, presetType });

      expect(state).toMatchObject({
        timeframeRangeType,
        presetType,
        timeframe: getTimeframeForRangeType({
          timeframeRangeType,
          presetType,
        }),
        epics: [],
        childrenFlags: {},
        epicIds: [],
      });
    });
  });

  describe('SET_SORTED_BY', () => {
    it('Should set `sortedBy` to the state and reset existing parent epics and children epics', () => {
      const sortedBy = 'start_date_asc';
      setEpicMockData(state);

      mutations[types.SET_SORTED_BY](state, sortedBy);

      expect(state).toMatchObject({
        childrenEpics: {},
        childrenFlags: {},
        epicIds: [],
        epics: [],
        sortedBy,
      });
    });
  });

  describe('SET_PROGRESS_TRACKING', () => {
    it('Should set `progressTracking` to the state', () => {
      const progressTracking = PROGRESS_COUNT;

      mutations[types.SET_PROGRESS_TRACKING](state, progressTracking);

      expect(state).toMatchObject({
        progressTracking,
      });
    });
  });

  describe('TOGGLE_PROGRESS_TRACKING_ACTIVE', () => {
    it('Should toggle `progressTracking` on state', () => {
      expect(state).toMatchObject({
        isProgressTrackingActive: true,
      });

      mutations[types.TOGGLE_PROGRESS_TRACKING_ACTIVE](state);

      expect(state).toMatchObject({
        isProgressTrackingActive: false,
      });
    });
  });

  describe('SET_MILESTONES_TYPE', () => {
    it('Should set `milestonesType` to the state', () => {
      const milestonesType = MILESTONES_GROUP;
      setEpicMockData(state);

      mutations[types.SET_MILESTONES_TYPE](state, milestonesType);

      expect(state).toMatchObject({
        milestonesType,
      });
    });
  });

  describe('TOGGLE_MILESTONES', () => {
    it('Should toggle `isShowingMilestones` on state', () => {
      expect(state).toMatchObject({
        isShowingMilestones: true,
      });

      mutations[types.TOGGLE_MILESTONES](state);

      expect(state).toMatchObject({
        isShowingMilestones: false,
      });
    });
  });

  describe('TOGGLE_LABELS', () => {
    it('Should toggle `isShowingLabels` on state', () => {
      expect(state).toMatchObject({
        isShowingLabels: false,
      });

      mutations[types.TOGGLE_LABELS](state);

      expect(state).toMatchObject({
        isShowingLabels: true,
      });
    });
  });
});
