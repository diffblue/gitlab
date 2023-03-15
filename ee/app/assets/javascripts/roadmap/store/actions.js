import { createAlert } from '~/alert';
import { s__ } from '~/locale';

import { ROADMAP_PAGE_SIZE } from '../constants';
import epicChildEpics from '../queries/epic_child_epics.query.graphql';
import groupEpics from '../queries/group_epics.query.graphql';
import groupEpicsWithColor from '../queries/group_epics_with_color.query.graphql';
import groupMilestones from '../queries/group_milestones.query.graphql';
import * as epicUtils from '../utils/epic_utils';
import * as roadmapItemUtils from '../utils/roadmap_item_utils';
import { getEpicsTimeframeRange, sortEpics } from '../utils/roadmap_utils';

import * as types from './mutation_types';

export const setInitialData = ({ commit }, data) => commit(types.SET_INITIAL_DATA, data);

const fetchGroupEpics = (
  { epicIid, fullPath, epicsState, sortedBy, presetType, filterParams, timeframe },
  { timeframe: defaultTimeframe, endCursor },
) => {
  let query;
  let variables = {
    fullPath,
    state: epicsState,
    sort: sortedBy,
    endCursor,
    ...getEpicsTimeframeRange({
      presetType,
      timeframe: defaultTimeframe || timeframe,
    }),
  };

  const transformedFilterParams = epicUtils.transformFetchEpicFilterParams(filterParams);

  // When epicIid is present,
  // Roadmap is being accessed from within an Epic,
  // and then we don't need to pass `transformedFilterParams`.
  if (epicIid) {
    query = epicChildEpics;
    variables.iid = epicIid;
    variables.withColor = Boolean(gon?.features?.epicColorHighlight);
  } else {
    query = gon?.features?.epicColorHighlight ? groupEpicsWithColor : groupEpics;
    variables = {
      ...variables,
      ...transformedFilterParams,
      first: ROADMAP_PAGE_SIZE,
      topLevelHierarchyOnly: true,
    };

    if (transformedFilterParams?.epicIid) {
      variables.iid = transformedFilterParams.epicIid.split('::&').pop();
      variables.topLevelHierarchyOnly = false;
    }
    if (transformedFilterParams?.groupPath) {
      variables.fullPath = transformedFilterParams.groupPath;
      variables.includeDescendantGroups = false;
    }
  }

  return epicUtils.gqClient
    .query({
      query,
      variables,
    })
    .then(({ data }) => {
      const edges = epicIid
        ? data?.group?.epic?.children?.edges || []
        : data?.group?.epics?.edges || [];

      return {
        rawEpics: edges.map((e) => e.node),
        pageInfo: data?.group?.epics?.pageInfo,
      };
    });
};

const fetchChildrenEpics = (state, { parentItem }) => {
  const { iid, group } = parentItem;
  const { filterParams, epicsState, sortedBy } = state;

  return epicUtils.gqClient
    .query({
      query: epicChildEpics,
      variables: {
        iid,
        fullPath: group?.fullPath,
        state: epicsState,
        sort: sortedBy,
        withColor: Boolean(gon?.features?.epicColorHighlight),
        ...filterParams,
      },
    })
    .then(({ data }) => {
      const edges = data?.group?.epic?.children?.edges || [];
      return edges.map((e) => e.node);
    });
};

export const receiveEpicsSuccess = (
  { commit, dispatch, state },
  { rawEpics, pageInfo, newEpic, timeframeExtended, appendToList },
) => {
  const epicIds = [];
  const epics = rawEpics.reduce((filteredEpics, epic) => {
    const { presetType, timeframe } = state;
    const formattedEpic = roadmapItemUtils.formatRoadmapItemDetails(
      epic,
      roadmapItemUtils.timeframeStartDate(presetType, timeframe),
      roadmapItemUtils.timeframeEndDate(presetType, timeframe),
    );

    formattedEpic.isChildEpic = false;

    // Exclude any Epic that has invalid dates
    // or is already present in Roadmap timeline
    if (
      formattedEpic.startDate.getTime() <= formattedEpic.endDate.getTime() &&
      state.epicIds.indexOf(formattedEpic.id) < 0
    ) {
      Object.assign(formattedEpic, {
        newEpic,
      });
      filteredEpics.push(formattedEpic);
      epicIds.push(formattedEpic.id);
    }
    return filteredEpics;
  }, []);

  commit(types.UPDATE_EPIC_IDS, epicIds);
  dispatch('initItemChildrenFlags', { epics });

  if (timeframeExtended) {
    const updatedEpics = state.epics.concat(epics);
    sortEpics(updatedEpics, state.sortedBy);
    commit(types.RECEIVE_EPICS_FOR_TIMEFRAME_SUCCESS, updatedEpics);
  } else if (appendToList) {
    const updatedEpics = state.epics.concat(epics);
    commit(types.RECEIVE_EPICS_FOR_NEXT_PAGE_SUCCESS, { epics: updatedEpics, pageInfo });
  } else {
    commit(types.RECEIVE_EPICS_SUCCESS, { epics, pageInfo });
  }
};
export const receiveEpicsFailure = ({ commit }) => {
  commit(types.RECEIVE_EPICS_FAILURE);
  createAlert({
    message: s__('GroupRoadmap|Something went wrong while fetching epics'),
  });
};

export const requestChildrenEpics = ({ commit }, { parentItemId }) => {
  commit(types.REQUEST_CHILDREN_EPICS, { parentItemId });
};
export const receiveChildrenSuccess = (
  { commit, dispatch, state },
  { parentItemId, rawChildren },
) => {
  const children = rawChildren.reduce((filteredChildren, epic) => {
    const { presetType, timeframe } = state;
    const formattedChild = roadmapItemUtils.formatRoadmapItemDetails(
      epic,
      roadmapItemUtils.timeframeStartDate(presetType, timeframe),
      roadmapItemUtils.timeframeEndDate(presetType, timeframe),
    );

    formattedChild.isChildEpic = true;

    // Exclude any Epic that has invalid dates
    if (formattedChild.startDate.getTime() <= formattedChild.endDate.getTime()) {
      filteredChildren.push(formattedChild);
    }
    return filteredChildren;
  }, []);
  dispatch('expandEpic', {
    parentItemId,
  });
  dispatch('initItemChildrenFlags', { epics: children });
  commit(types.RECEIVE_CHILDREN_SUCCESS, { parentItemId, children });
};

export const fetchEpics = ({ state, commit, dispatch }, { endCursor } = {}) => {
  if (endCursor) {
    commit(types.REQUEST_EPICS_FOR_NEXT_PAGE);
  } else {
    commit(types.REQUEST_EPICS);
  }

  return fetchGroupEpics(state, { endCursor })
    .then(({ rawEpics, pageInfo }) => {
      dispatch('receiveEpicsSuccess', {
        rawEpics,
        pageInfo,
        appendToList: Boolean(endCursor),
      });
    })
    .catch(() => dispatch('receiveEpicsFailure'));
};

export const initItemChildrenFlags = ({ commit }, data) =>
  commit(types.INIT_EPIC_CHILDREN_FLAGS, data);

export const expandEpic = ({ commit }, { parentItemId }) =>
  commit(types.EXPAND_EPIC, { parentItemId });
export const collapseEpic = ({ commit }, { parentItemId }) =>
  commit(types.COLLAPSE_EPIC, { parentItemId });

export const toggleEpic = ({ state, dispatch }, { parentItem }) => {
  const parentItemId = parentItem.id;
  if (!state.childrenFlags[parentItemId].itemExpanded) {
    if (!state.childrenEpics[parentItemId]) {
      dispatch('requestChildrenEpics', { parentItemId });
      fetchChildrenEpics(state, { parentItem })
        .then((rawChildren) => {
          dispatch('receiveChildrenSuccess', {
            parentItemId,
            rawChildren,
          });
        })
        .catch(() => dispatch('receiveEpicsFailure'));
    } else {
      dispatch('expandEpic', {
        parentItemId,
      });
    }
  } else {
    dispatch('collapseEpic', {
      parentItemId,
    });
  }
};

export const fetchGroupMilestones = (
  { fullPath, presetType, filterParams, timeframe },
  defaultTimeframe,
) => {
  const query = groupMilestones;
  const variables = {
    fullPath,
    state: 'active',
    ...getEpicsTimeframeRange({
      presetType,
      timeframe: defaultTimeframe || timeframe,
    }),
    includeDescendants: true,
    includeAncestors: true,
    searchTitle: filterParams.milestoneTitle,
  };

  return epicUtils.gqClient
    .query({
      query,
      variables,
    })
    .then(({ data }) => {
      const { group } = data;

      const edges = (group.milestones && group.milestones.edges) || [];

      return roadmapItemUtils.extractGroupMilestones(edges);
    });
};

export const requestMilestones = ({ commit }) => commit(types.REQUEST_MILESTONES);

export const fetchMilestones = ({ state, dispatch }) => {
  dispatch('requestMilestones');

  return fetchGroupMilestones(state)
    .then((rawMilestones) => {
      dispatch('receiveMilestonesSuccess', { rawMilestones });
    })
    .catch(() => dispatch('receiveMilestonesFailure'));
};

export const receiveMilestonesSuccess = (
  { commit, state },
  { rawMilestones, newMilestone }, // timeframeExtended
) => {
  const { presetType, timeframe } = state;
  const milestoneIds = [];
  const milestones = rawMilestones.reduce((filteredMilestones, milestone) => {
    const formattedMilestone = roadmapItemUtils.formatRoadmapItemDetails(
      milestone,
      roadmapItemUtils.timeframeStartDate(presetType, timeframe),
      roadmapItemUtils.timeframeEndDate(presetType, timeframe),
    );
    // Exclude any Milestone that has invalid dates
    // or is already present in Roadmap timeline
    if (
      formattedMilestone.startDate.getTime() <= formattedMilestone.endDate.getTime() &&
      state.milestoneIds.indexOf(formattedMilestone.id) < 0
    ) {
      Object.assign(formattedMilestone, {
        newMilestone,
      });
      filteredMilestones.push(formattedMilestone);
      milestoneIds.push(formattedMilestone.id);
    }
    return filteredMilestones;
  }, []);

  commit(types.UPDATE_MILESTONE_IDS, milestoneIds);
  commit(types.RECEIVE_MILESTONES_SUCCESS, milestones);
};

export const receiveMilestonesFailure = ({ commit }) => {
  commit(types.RECEIVE_MILESTONES_FAILURE);
  createAlert({
    message: s__('GroupRoadmap|Something went wrong while fetching milestones'),
  });
};

export const refreshMilestoneDates = ({ commit, state }) => {
  const { presetType, timeframe } = state;

  const milestones = state.milestones.map((milestone) =>
    roadmapItemUtils.processRoadmapItemDates(
      milestone,
      roadmapItemUtils.timeframeStartDate(presetType, timeframe),
      roadmapItemUtils.timeframeEndDate(presetType, timeframe),
    ),
  );

  commit(types.SET_MILESTONES, milestones);
};

export const setBufferSize = ({ commit }, bufferSize) => commit(types.SET_BUFFER_SIZE, bufferSize);

export const setEpicsState = ({ commit }, epicsState) => commit(types.SET_EPICS_STATE, epicsState);

export const setDaterange = ({ commit }, { timeframeRangeType, presetType }) =>
  commit(types.SET_DATERANGE, { timeframeRangeType, presetType });

export const setFilterParams = ({ commit }, filterParams) =>
  commit(types.SET_FILTER_PARAMS, filterParams);

export const setSortedBy = ({ commit }, sortedBy) => commit(types.SET_SORTED_BY, sortedBy);

export const setProgressTracking = ({ commit }, progressTracking) =>
  commit(types.SET_PROGRESS_TRACKING, progressTracking);

export const toggleProgressTrackingActive = ({ commit }) =>
  commit(types.TOGGLE_PROGRESS_TRACKING_ACTIVE);

export const setMilestonesType = ({ commit }, milestonesType) =>
  commit(types.SET_MILESTONES_TYPE, milestonesType);

export const toggleMilestones = ({ commit }) => commit(types.TOGGLE_MILESTONES);

export const toggleLabels = ({ commit }) => commit(types.TOGGLE_LABELS);
