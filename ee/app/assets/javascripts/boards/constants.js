/* eslint-disable import/export */
import { issuableTypes, FilterFields as FilterFieldsCE } from '~/boards/constants';
import destroyBoardListMutation from '~/boards/graphql/board_list_destroy.mutation.graphql';
import updateBoardListMutation from '~/boards/graphql/board_list_update.mutation.graphql';

import { s__ } from '~/locale';

import boardListsQuery from './graphql/board_lists.query.graphql';
import destroyEpicBoardListMutation from './graphql/epic_board_list_destroy.mutation.graphql';
import updateEpicBoardListMutation from './graphql/epic_board_list_update.mutation.graphql';
import epicBoardListsQuery from './graphql/epic_board_lists.query.graphql';

export * from '~/boards/constants';

export const DRAGGABLE_TAG = 'div';

export const EPIC_LANE_BASE_HEIGHT = 40;

/* eslint-disable @gitlab/require-i18n-strings */
export const EpicFilterType = {
  any: 'Any',
  none: 'None',
};

export const FilterFields = {
  [issuableTypes.issue]: [
    ...FilterFieldsCE[issuableTypes.issue],
    'epicId',
    'epicWildcardId',
    'weight',
    'iterationId',
    'iterationTitle',
    'iterationWildcardId',
  ],
  [issuableTypes.epic]: ['authorUsername', 'labelName', 'search', 'myReactionEmoji'],
};

export const IterationFilterType = {
  any: 'Any',
  none: 'None',
  current: 'Current',
};

export const IterationIDs = {
  NONE: 'gid://gitlab/Iteration/0',
  CURRENT: 'gid://gitlab/Iteration/-4',
};

export const MilestoneFilterType = {
  any: 'Any',
  none: 'None',
};

export const MilestoneIDs = {
  NONE: 0,
  ANY: -1,
};

export const ANY_MILESTONE = {
  id: 'gid://gitlab/Milestone/-1',
  title: s__('BoardScope|Any Milestone'),
};
export const NO_MILESTONE = {
  id: 'gid://gitlab/Milestone/0',
  title: s__('BoardScope|No milestone'),
};
export const UPCOMING_MILESTONE = {
  id: 'gid://gitlab/Milestone/-2',
  title: s__('BoardScope|Upcoming'),
};
export const STARTED_MILESTONE = {
  id: 'gid://gitlab/Milestone/-3',
  title: s__('BoardScope|Started'),
};

export const MilestonesPreset = [
  ANY_MILESTONE,
  NO_MILESTONE,
  UPCOMING_MILESTONE,
  STARTED_MILESTONE,
];

export const ANY_ASSIGNEE = {
  id: 'gid://gitlab/User/-1',
  name: s__('BoardScope|Any assignee'),
};
export const AssigneesPreset = [ANY_ASSIGNEE];

export const WeightFilterType = {
  none: 'None',
};

export const WeightIDs = {
  NONE: -2,
  ANY: -1,
};

export const GroupByParamType = {
  epic: 'epic',
};

export const ErrorMessages = {
  fetchIssueError: s__(
    'Boards|An error occurred while fetching the board issues. Please reload the page.',
  ),
  fetchEpicsError: s__(
    'Boards|An error occurred while fetching the board epics. Please reload the page.',
  ),
};

export const listsQuery = {
  [issuableTypes.issue]: {
    query: boardListsQuery,
  },
  [issuableTypes.epic]: {
    query: epicBoardListsQuery,
  },
};

export const updateListQueries = {
  [issuableTypes.issue]: {
    mutation: updateBoardListMutation,
  },
  [issuableTypes.epic]: {
    mutation: updateEpicBoardListMutation,
  },
};

export const deleteListQueries = {
  [issuableTypes.issue]: {
    mutation: destroyBoardListMutation,
  },
  [issuableTypes.epic]: {
    mutation: destroyEpicBoardListMutation,
  },
};

export default {
  DRAGGABLE_TAG,
  EpicFilterType,
};
