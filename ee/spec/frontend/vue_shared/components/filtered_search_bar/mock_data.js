import {
  OPERATORS_IS,
  TOKEN_TYPE_EPIC,
  TOKEN_TYPE_HEALTH,
  TOKEN_TYPE_ITERATION,
  TOKEN_TYPE_WEIGHT,
} from '~/vue_shared/components/filtered_search_bar/constants';
import {
  TOKEN_TITLE_EPIC,
  TOKEN_TITLE_HEALTH,
  TOKEN_TITLE_ITERATION,
  TOKEN_TITLE_WEIGHT,
} from 'ee/vue_shared/components/filtered_search_bar/constants';
import EpicToken from 'ee/vue_shared/components/filtered_search_bar/tokens/epic_token.vue';
import HealthToken from 'ee/vue_shared/components/filtered_search_bar/tokens/health_token.vue';
import IterationToken from 'ee/vue_shared/components/filtered_search_bar/tokens/iteration_token.vue';
import WeightToken from 'ee/vue_shared/components/filtered_search_bar/tokens/weight_token.vue';

export const mockEpics = [
  { iid: 1, id: 1, title: 'Foo', group_full_path: 'gitlab-org' },
  { iid: 2, id: 2, title: 'Bar', group_full_path: 'gitlab-org/design' },
];

export const mockIterationToken = {
  type: TOKEN_TYPE_ITERATION,
  icon: 'iteration',
  title: TOKEN_TITLE_ITERATION,
  unique: true,
  token: IterationToken,
  fetchIterations: () => Promise.resolve(),
};

export const mockIterations = [
  {
    id: 1,
    title: 'Iteration 1',
    startDate: '2021-11-05',
    dueDate: '2021-11-10',
    iterationCadence: {
      title: 'Cadence 1',
    },
  },
];

export const mockEpicToken = {
  type: TOKEN_TYPE_EPIC,
  icon: 'clock',
  title: TOKEN_TITLE_EPIC,
  unique: true,
  symbol: '&',
  token: EpicToken,
  operators: OPERATORS_IS,
  idProperty: 'iid',
  fullPath: 'gitlab-org',
};

const mockEpicNode1 = {
  id: 'gid://gitlab/Epic/40',
  iid: '2',
  group: {
    id: 'gid://gitlab/Group/9970',
    fullPath: 'gitlab-org',
    __typename: 'Group',
  },
  title: 'Marketing epic',
  state: 'opened',
  reference: '\u00269961',
  referencePath: 'gitlab-org\u00269961',
  webPath: '/groups/gitlab-org/-/epics/9961',
  webUrl: 'https://gitlab.com/groups/gitlab-org/-/epics/9961',
  createdAt: '2023-02-24T19:27:21Z',
  closedAt: null,
  __typename: 'Epic',
};

const mockEpicNode2 = {
  id: 'gid://gitlab/Epic/753769',
  iid: '9926',
  group: {
    id: 'gid://gitlab/Group/9970',
    fullPath: 'gitlab-org',
    __typename: 'Group',
  },
  title: 'Undesired behavior with combining filter criteria on Issues List',
  state: 'opened',
  reference: '\u00269926',
  referencePath: 'gitlab-org\u00269926',
  webPath: '/groups/gitlab-org/-/epics/9926',
  webUrl: 'https://gitlab.com/groups/gitlab-org/-/epics/9926',
  createdAt: '2023-02-21T16:42:41Z',
  closedAt: null,
  __typename: 'Epic',
};

export const mockGroupEpicsQueryResponse = {
  data: {
    group: {
      id: 'gid://gitlab/Group/1',
      name: 'Gitlab Org',
      epics: {
        nodes: [
          {
            ...mockEpicNode1,
          },
          {
            ...mockEpicNode2,
          },
        ],
        __typename: 'EpicConnection',
      },
      __typename: 'Group',
    },
  },
};

export const mockWeightToken = {
  type: TOKEN_TYPE_WEIGHT,
  icon: 'weight',
  title: TOKEN_TITLE_WEIGHT,
  unique: true,
  token: WeightToken,
};

export const mockHealthToken = {
  type: TOKEN_TYPE_HEALTH,
  icon: 'status-health',
  title: TOKEN_TITLE_HEALTH,
  unique: true,
  operators: OPERATORS_IS,
  token: HealthToken,
};
