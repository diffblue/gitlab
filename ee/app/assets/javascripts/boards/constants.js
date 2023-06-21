/* eslint-disable import/export */
import { FilterFields as FilterFieldsCE } from '~/boards/constants';
import destroyBoardListMutation from '~/boards/graphql/board_list_destroy.mutation.graphql';
import updateBoardListMutation from '~/boards/graphql/board_list_update.mutation.graphql';
import listIssuesQuery from '~/boards/graphql/lists_issues.query.graphql';
import { TYPENAME_ISSUE, TYPENAME_EPIC } from '~/graphql_shared/constants';
import { TYPE_EPIC, TYPE_ISSUE } from '~/issues/constants';
import { s__ } from '~/locale';

import toggleListCollapsedMutation from '~/boards/graphql/client/board_toggle_collapsed.mutation.graphql';
import issueCreateMutation from '~/boards/graphql/issue_create.mutation.graphql';
import issueMoveListMutation from './graphql/issue_move_list.mutation.graphql';
import boardListsQuery from './graphql/board_lists.query.graphql';
import destroyEpicBoardListMutation from './graphql/epic_board_list_destroy.mutation.graphql';
import updateEpicBoardListMutation from './graphql/epic_board_list_update.mutation.graphql';
import epicBoardListsQuery from './graphql/epic_board_lists.query.graphql';
import listEpicsQuery from './graphql/lists_epics.query.graphql';
import listEpicsWithColorQuery from './graphql/lists_epics_with_color.query.graphql';
import listDeferredQuery from './graphql/board_lists_deferred.query.graphql';
import epicListDeferredQuery from './graphql/epic_board_lists_deferred.query.graphql';
import createBoardListMutation from './graphql/board_list_create.mutation.graphql';
import createEpicBoardListMutation from './graphql/epic_board_list_create.mutation.graphql';
import epicMoveListMutation from './graphql/epic_move_list.mutation.graphql';
import toggleEpicListCollapsedMutation from './graphql/client/epic_board_toggle_collapsed.mutation.graphql';
import epicCreateMutation from './graphql/epic_create.mutation.graphql';

export * from '~/boards/constants';

export const DRAGGABLE_TAG = 'div';

export const EPIC_LANE_BASE_HEIGHT = 40;

export const GroupByParamType = {
  epic: 'epic',
};

/* eslint-disable @gitlab/require-i18n-strings */
export const EpicFilterType = {
  any: 'Any',
  none: 'None',
};

export const HealthStatusFilterType = {
  any: 'Any',
  none: 'None',
};

export const IterationFilterType = {
  any: 'Any',
  none: 'None',
  current: 'Current',
};

export const WeightFilterType = {
  none: 'None',
};
/* eslint-enable @gitlab/require-i18n-strings */

export const FilterFields = {
  [TYPE_ISSUE]: [
    ...FilterFieldsCE[TYPE_ISSUE],
    'epicId',
    'epicWildcardId',
    'weight',
    'iterationId',
    'iterationTitle',
    'iterationWildcardId',
    'iterationCadenceId',
    'healthStatusFilter',
  ],
  [TYPE_EPIC]: ['authorUsername', 'labelName', 'search', 'myReactionEmoji'],
};

export const IterationIDs = {
  NONE: 'gid://gitlab/Iteration/0',
  ANY: 'gid://gitlab/Iteration/-1',
  CURRENT: 'gid://gitlab/Iteration/-4',
};

export const ANY_ITERATION = {
  id: 'gid://gitlab/Iteration/-1',
  title: s__('BoardScope|Any iteration'),
  iterationCadenceId: null,
};

export const NO_ITERATION = {
  id: 'gid://gitlab/Iteration/0',
  title: s__('BoardScope|No iteration'),
  iterationCadenceId: null,
};

export const CURRENT_ITERATION = {
  id: 'gid://gitlab/Iteration/-4',
  title: s__('BoardScope|Current iteration'),
  iterationCadenceId: null,
};

export const IterationsPreset = [ANY_ITERATION, NO_ITERATION, CURRENT_ITERATION];

export const MilestoneIDs = {
  NONE: 0,
  ANY: -1,
};

export const DONT_FILTER_MILESTONE = {
  id: null,
  title: s__("BoardScope|Don't filter milestone"),
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
  DONT_FILTER_MILESTONE,
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

export const WeightIDs = {
  NONE: -2,
  ANY: -1,
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
  [TYPE_ISSUE]: {
    query: boardListsQuery,
  },
  [TYPE_EPIC]: {
    query: epicBoardListsQuery,
  },
};

export const listsDeferredQuery = {
  [TYPE_ISSUE]: {
    query: listDeferredQuery,
  },
  [TYPE_EPIC]: {
    query: epicListDeferredQuery,
  },
};

export const createListMutations = {
  [TYPE_ISSUE]: {
    mutation: createBoardListMutation,
  },
  [TYPE_EPIC]: {
    mutation: createEpicBoardListMutation,
  },
};

export const updateListQueries = {
  [TYPE_ISSUE]: {
    mutation: updateBoardListMutation,
  },
  [TYPE_EPIC]: {
    mutation: updateEpicBoardListMutation,
  },
};

export const toggleCollapsedMutations = {
  [TYPE_ISSUE]: {
    mutation: toggleListCollapsedMutation,
  },
  [TYPE_EPIC]: {
    mutation: toggleEpicListCollapsedMutation,
  },
};

export const deleteListQueries = {
  [TYPE_ISSUE]: {
    mutation: destroyBoardListMutation,
  },
  [TYPE_EPIC]: {
    mutation: destroyEpicBoardListMutation,
  },
};

export const listIssuablesQueries = {
  [TYPE_ISSUE]: {
    query: listIssuesQuery,
    moveMutation: issueMoveListMutation,
    createMutation: issueCreateMutation,
    optimisticResponse: {
      assignees: { nodes: [], __typename: 'UserCoreConnection' },
      blocked: false,
      blockedByCount: 0,
      confidential: false,
      dueDate: null,
      emailsDisabled: false,
      epic: null,
      healthStatus: null,
      hidden: false,
      humanTimeEstimate: null,
      humanTotalTimeSpent: null,
      id: 'gid://gitlab/Issue/-1',
      iid: '-1',
      iteration: null,
      labels: { nodes: [], __typename: 'LabelConnection' },
      milestone: null,
      referencePath: ' ',
      relativePosition: null,
      severity: 'UNKNOWN',
      timeEstimate: 0,
      title: '',
      totalTimeSpent: 0,
      type: 'ISSUE',
      webUrl: '',
      weight: null,
      __typename: TYPENAME_ISSUE,
    },
  },
  [TYPE_EPIC]: {
    query: gon?.features?.epicColorHighlight ? listEpicsWithColorQuery : listEpicsQuery,
    moveMutation: epicMoveListMutation,
    createMutation: epicCreateMutation,
    optimisticResponse: {
      blocked: false,
      blockedByCount: 0,
      closedAt: null,
      confidential: false,
      createdAt: null,
      descendantCounts: {
        closedEpics: 0,
        closedIssues: 0,
        openedEpics: 0,
        openedIssues: 0,
        __typename: 'EpicDescendantCount',
      },
      descendantWeightSum: {
        closedIssues: 0,
        openedIssues: 0,
        __typename: 'EpicDescendantWeights',
      },
      group: null,
      hasIssues: false,
      id: 'gid://gitlab/Epic/-1',
      iid: '-1',
      labels: { nodes: [], __typename: 'LabelConnection' },
      reference: '',
      referencePath: ' ',
      relativePosition: null,
      state: 'opened',
      subscribed: true,
      title: '',
      webPath: '',
      webUrl: '',
      ...(gon?.features?.epicColorHighlight ? { color: '' } : {}),
      __typename: TYPENAME_EPIC,
    },
  },
};

export default {
  DRAGGABLE_TAG,
  EpicFilterType,
};
