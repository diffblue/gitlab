import Vue from 'vue';

import { getTimeframeForRangeType } from '../utils/roadmap_utils';
import * as types from './mutation_types';

const resetEpics = (state) => {
  state.epics = [];
  state.childrenFlags = {};
  state.epicIds = [];
  state.childrenEpics = {};
};

export default {
  [types.SET_INITIAL_DATA](state, data) {
    Object.assign(state, { ...data });
  },

  [types.SET_EPICS](state, epics) {
    state.epics = epics;
  },

  [types.UPDATE_EPIC_IDS](state, epicIds) {
    state.epicIds.push(...epicIds);
  },

  [types.REQUEST_EPICS](state) {
    state.epicsFetchInProgress = true;
  },
  [types.REQUEST_EPICS_FOR_TIMEFRAME](state) {
    state.epicsFetchForTimeframeInProgress = true;
  },
  [types.REQUEST_EPICS_FOR_NEXT_PAGE](state) {
    state.epicsFetchForNextPageInProgress = true;
  },
  [types.RECEIVE_EPICS_SUCCESS](state, { epics, pageInfo }) {
    state.epicsFetchResultEmpty = epics.length === 0;

    if (!state.epicsFetchResultEmpty) {
      state.epics = epics;
      state.pageInfo = pageInfo;
    }

    state.epicsFetchInProgress = false;
  },
  [types.RECEIVE_EPICS_FOR_TIMEFRAME_SUCCESS](state, epics) {
    state.epics = epics;
    state.epicsFetchForTimeframeInProgress = false;
  },
  [types.RECEIVE_EPICS_FOR_NEXT_PAGE_SUCCESS](state, { epics, pageInfo }) {
    state.epics = epics;
    state.pageInfo = pageInfo;
    state.epicsFetchForNextPageInProgress = false;
  },
  [types.RECEIVE_EPICS_FAILURE](state) {
    state.epicsFetchInProgress = false;
    state.epicsFetchForTimeframeInProgress = false;
    state.epicsFetchForNextPageInProgress = false;
    state.epicsFetchFailure = true;
    Object.keys(state.childrenEpics).forEach((id) => {
      Vue.set(state.childrenFlags, id, {
        itemChildrenFetchInProgress: false,
      });
    });
  },

  [types.REQUEST_CHILDREN_EPICS](state, { parentItemId }) {
    state.childrenFlags[parentItemId].itemChildrenFetchInProgress = true;
  },
  [types.RECEIVE_CHILDREN_SUCCESS](state, { parentItemId, children }) {
    Vue.set(state.childrenEpics, parentItemId, children);
    state.childrenFlags[parentItemId].itemChildrenFetchInProgress = false;
  },

  [types.INIT_EPIC_CHILDREN_FLAGS](state, { epics }) {
    epics.forEach((item) => {
      Vue.set(state.childrenFlags, item.id, {
        itemExpanded: false,
        itemChildrenFetchInProgress: false,
      });
    });
  },

  [types.EXPAND_EPIC](state, { parentItemId }) {
    state.childrenFlags[parentItemId].itemExpanded = true;
  },
  [types.COLLAPSE_EPIC](state, { parentItemId }) {
    state.childrenFlags[parentItemId].itemExpanded = false;
  },

  [types.SET_MILESTONES](state, milestones) {
    state.milestones = milestones;
  },
  [types.UPDATE_MILESTONE_IDS](state, milestoneIds) {
    state.milestoneIds.push(...milestoneIds);
  },
  [types.REQUEST_MILESTONES](state) {
    state.milestonesFetchInProgress = true;
    state.milestones = [];
    state.milestoneIds = [];
  },
  [types.RECEIVE_MILESTONES_SUCCESS](state, milestones) {
    state.milestonesFetchInProgress = false;
    state.milestonesFetchResultEmpty = milestones.length === 0;

    if (!state.milestonesFetchResultEmpty) {
      state.milestones = milestones;
    }
  },
  [types.RECEIVE_MILESTONES_FAILURE](state) {
    state.milestonesFetchInProgress = false;
    state.milestonesFetchFailure = true;
  },

  [types.SET_BUFFER_SIZE](state, bufferSize) {
    state.bufferSize = bufferSize;
  },

  [types.SET_FILTER_PARAMS](state, filterParams) {
    state.filterParams = filterParams;
    state.hasFiltersApplied = Boolean(filterParams);
    resetEpics(state);
  },

  [types.SET_EPICS_STATE](state, epicsState) {
    state.epicsState = epicsState;
    resetEpics(state);
  },

  [types.SET_DATERANGE](state, { timeframeRangeType, presetType }) {
    state.timeframeRangeType = timeframeRangeType;
    state.presetType = presetType;
    state.timeframe = getTimeframeForRangeType({
      timeframeRangeType,
      presetType,
    });
    resetEpics(state);
  },

  [types.SET_SORTED_BY](state, sortedBy) {
    state.childrenEpics = {};
    state.sortedBy = sortedBy;
    resetEpics(state);
  },

  [types.SET_PROGRESS_TRACKING](state, progressTracking) {
    state.progressTracking = progressTracking;
  },

  [types.TOGGLE_PROGRESS_TRACKING_ACTIVE](state) {
    state.isProgressTrackingActive = !state.isProgressTrackingActive;
  },

  [types.SET_MILESTONES_TYPE](state, milestonesType) {
    state.milestonesType = milestonesType;
  },

  [types.TOGGLE_MILESTONES](state) {
    state.isShowingMilestones = !state.isShowingMilestones;
  },

  [types.TOGGLE_LABELS](state) {
    state.isShowingLabels = !state.isShowingLabels;
  },
};
