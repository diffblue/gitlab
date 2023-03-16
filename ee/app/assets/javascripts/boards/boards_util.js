import { sortBy } from 'lodash';
import {
  FiltersInfo as FiltersInfoCE,
  formatIssueInput as formatIssueInputCe,
} from '~/boards/boards_util';
import { boardQuery } from '~/boards/constants';
import {
  TYPENAME_EPIC_BOARD,
  TYPENAME_ITERATION,
  TYPENAME_ITERATIONS_CADENCE,
  TYPENAME_EPIC,
  TYPENAME_MILESTONE,
  TYPENAME_USER,
} from '~/graphql_shared/constants';
import { getIdFromGraphQLId, convertToGraphQLId } from '~/graphql_shared/utils';
import { objectToQuery, queryToObject } from '~/lib/utils/url_utility';
import {
  EPIC_LANE_BASE_HEIGHT,
  IterationFilterType,
  IterationIDs,
  HealthStatusFilterType,
  ListType,
  MilestoneFilterType,
  MilestoneIDs,
  WeightFilterType,
  WeightIDs,
  EpicFilterType,
} from './constants';
import epicBoardQuery from './graphql/epic_board.query.graphql';

export {
  formatBoardLists,
  formatListIssues,
  formatListsPageInfo,
  formatIssue,
  updateListPosition,
  moveItemListHelper,
  getMoveData,
  filterVariables,
  fullBoardId,
} from '~/boards/boards_util';

export function getMilestone({ milestone }) {
  return milestone || null;
}

export function fullEpicId(epicId) {
  return convertToGraphQLId(TYPENAME_EPIC, epicId);
}

export function fullMilestoneId(milestoneId) {
  return convertToGraphQLId(TYPENAME_MILESTONE, milestoneId);
}

function fullIterationId(id) {
  if (!id) {
    return null;
  }

  if (id === IterationIDs.CURRENT) {
    return 'CURRENT';
  }

  if (id === IterationIDs.UPCOMING) {
    return 'UPCOMING';
  }

  return convertToGraphQLId(TYPENAME_ITERATION, id);
}

function fullIterationCadenceId(id) {
  if (!id) {
    return null;
  }

  return convertToGraphQLId(TYPENAME_ITERATIONS_CADENCE, getIdFromGraphQLId(id));
}

export function fullUserId(userId) {
  return convertToGraphQLId(TYPENAME_USER, userId);
}

export function fullEpicBoardId(epicBoardId) {
  return convertToGraphQLId(TYPENAME_EPIC_BOARD, epicBoardId);
}

export function calculateSwimlanesBufferSize(listTopCoordinate) {
  return Math.ceil((window.innerHeight - listTopCoordinate) / EPIC_LANE_BASE_HEIGHT);
}

export function formatEpic(epic) {
  return {
    ...epic,
    labels: epic.labels?.nodes || [],
    // Epics don't support assignees as of now
    // but `<board-card-inner>` expects it.
    // So until https://gitlab.com/gitlab-org/gitlab/-/issues/238444
    // is addressed, we need to pass empty array.
    assignees: [],
  };
}

export function formatListEpics(listEpics) {
  const boardItems = {};
  let listItemsCount;

  const listData = listEpics.nodes.reduce((map, list) => {
    listItemsCount = list.epicsCount;
    const sortedEpics = list.epics.nodes;

    return {
      ...map,
      [list.id]: sortedEpics.map((i) => {
        const { id } = i;

        const listEpic = {
          ...i,
          labels: i.labels?.nodes || [],
          assignees: i.assignees?.nodes || [],
        };

        boardItems[id] = listEpic;

        return id;
      }),
    };
  }, {});

  return { listData, boardItems, listItemsCount };
}

export function formatEpicListsPageInfo(lists) {
  const listData = lists.nodes.reduce((map, list) => {
    return {
      ...map,
      [list.id]: list.epics.pageInfo,
    };
  }, {});
  return listData;
}

export function formatEpicInput(epicInput, boardConfig) {
  const { labelIds = [], ...restEpicInput } = epicInput;
  return {
    ...restEpicInput,
    addLabelIds: [...labelIds, ...boardConfig.labelIds.map((id) => getIdFromGraphQLId(id))],
  };
}

function iterationObj(iterationId) {
  const isWildcard = Object.values(IterationIDs).includes(iterationId);
  const key = isWildcard ? 'iterationWildcardId' : 'iterationId';

  return {
    [key]: fullIterationId(iterationId),
  };
}

export function formatIssueInput(issueInput, boardConfig) {
  const { iterationId, iterationCadenceId } = boardConfig;

  return {
    ...formatIssueInputCe(issueInput, boardConfig),
    iterationCadenceId: fullIterationCadenceId(iterationCadenceId),
    ...iterationObj(iterationId),
  };
}

export function transformBoardConfig(boardConfig) {
  const updatedBoardConfig = {};
  const passedFilterParams = queryToObject(window.location.search, { gatherArrays: true });
  const updateScopeObject = (key, value = '') => {
    if (value === null || value === '') return;
    // Comparing with value string because weight can be a number
    if (!passedFilterParams[key] || passedFilterParams[key] !== value.toString()) {
      updatedBoardConfig[key] = value;
    }
  };

  let { milestoneTitle } = boardConfig;
  if (boardConfig.milestoneId === MilestoneIDs.NONE) {
    milestoneTitle = MilestoneFilterType.none;
  }
  if (milestoneTitle) {
    updateScopeObject('milestone_title', milestoneTitle);
  }

  const { iterationId, iterationCadenceId } = boardConfig;
  if (iterationId === IterationIDs.NONE) {
    updateScopeObject('iteration_id', IterationFilterType.none);
  } else if (iterationId === IterationIDs.ANY) {
    updateScopeObject('iteration_id', IterationFilterType.any);
    updateScopeObject('iteration_cadence_id', getIdFromGraphQLId(iterationCadenceId));
  } else if (iterationId === IterationIDs.CURRENT) {
    updateScopeObject('iteration_id', IterationFilterType.current);
    updateScopeObject('iteration_cadence_id', getIdFromGraphQLId(iterationCadenceId));
  } else if (iterationId) {
    updateScopeObject('iteration_id', getIdFromGraphQLId(iterationId));
  }

  let { weight } = boardConfig;
  if (weight !== WeightIDs.ANY) {
    if (weight === WeightIDs.NONE) {
      weight = WeightFilterType.none;
    }

    updateScopeObject('weight', weight);
  }

  updateScopeObject('assignee_username', boardConfig.assigneeUsername);

  let updatedFilterPath = objectToQuery(updatedBoardConfig);
  const filterPath = updatedFilterPath ? updatedFilterPath.split('&') : [];

  boardConfig.labels?.forEach((label) => {
    const labelTitle = encodeURIComponent(label.title);
    const param = `label_name[]=${labelTitle}`;

    if (!passedFilterParams.label_name?.includes(label.title)) {
      filterPath.push(param);
    }
  });

  updatedFilterPath = filterPath.join('&');
  return updatedFilterPath;
}

export const FiltersInfo = {
  ...FiltersInfoCE,
  epicId: {
    negatedSupport: true,
    transform: (epicId) => fullEpicId(epicId),
    // epic_id should be renamed to epicWildcardId when ANY or NONE is the value
    remap: (k, v) => (v === EpicFilterType.any || v === EpicFilterType.none ? 'epicWildcardId' : k),
  },
  epicWildcardId: {
    negatedSupport: false,
    transform: (val) => val.toUpperCase(),
  },
  iterationId: {
    negatedSupport: true,
    transform: (iterationId) => fullIterationId(iterationId),
    remap: (k, v) => {
      return v.endsWith(IterationFilterType.any) ||
        v.endsWith(IterationFilterType.none) ||
        v.endsWith(IterationFilterType.current)
        ? 'iterationWildcardId'
        : k;
    },
  },
  iterationTitle: {
    negatedSupport: true,
  },
  iterationWildcardId: {
    negatedSupport: true,
    transform: (val) => {
      // Gets the wildcard value out of the gid.
      const valList = val.split('/');
      return valList[valList.length - 1].toUpperCase();
    },
  },
  iterationCadenceId: {
    negatedSupport: false,
    transform: (iterationCadenceId) => fullIterationCadenceId(iterationCadenceId),
  },
  weight: {
    negatedSupport: true,
  },
  // healthStatus is deprecated in favour of healthStatusFilter
  healthStatus: {
    negatedSupport: true,
    remap: () => 'healthStatusFilter',
    transform: (v) =>
      v === HealthStatusFilterType.any || v === HealthStatusFilterType.none ? v.toUpperCase() : v,
  },
  healthStatusFilter: {
    negatedSupport: true,
    transform: (v) =>
      v === HealthStatusFilterType.any || v === HealthStatusFilterType.none ? v.toUpperCase() : v,
  },
};

export function getBoardQuery(boardType, isEpicBoard) {
  if (isEpicBoard) {
    return epicBoardQuery;
  }
  return boardQuery[boardType].query;
}

export function formatListIssuesForLanes(listIssues) {
  return listIssues.reduce((map, list) => {
    let sortedIssues = list.issues.nodes;
    if (list.listType !== ListType.closed) {
      sortedIssues = sortBy(sortedIssues, 'relativePosition');
    }

    return {
      ...map,
      [list.id]: sortedIssues,
    };
  }, {});
}

export default {
  getMilestone,
  fullEpicId,
  fullMilestoneId,
  fullUserId,
  fullEpicBoardId,
  transformBoardConfig,
};
