import { OPERATOR_IS_ONLY } from '~/vue_shared/components/filtered_search_bar/constants';
import EpicToken from 'ee/vue_shared/components/filtered_search_bar/tokens/epic_token.vue';
import HealthToken from 'ee/vue_shared/components/filtered_search_bar/tokens/health_token.vue';
import IterationToken from 'ee/vue_shared/components/filtered_search_bar/tokens/iteration_token.vue';
import WeightToken from 'ee/vue_shared/components/filtered_search_bar/tokens/weight_token.vue';

export const mockEpics = [
  { iid: 1, id: 1, title: 'Foo', group_full_path: 'gitlab-org' },
  { iid: 2, id: 2, title: 'Bar', group_full_path: 'gitlab-org/design' },
];

export const mockIterationToken = {
  type: 'iteration',
  icon: 'iteration',
  title: 'Iteration',
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
  type: 'epic_iid',
  icon: 'clock',
  title: 'Epic',
  unique: true,
  symbol: '&',
  token: EpicToken,
  operators: OPERATOR_IS_ONLY,
  idProperty: 'iid',
  fullPath: 'gitlab-org',
};

const mockEpicNode1 = {
  __typename: 'Epic',
  parent: null,
  id: 'gid://gitlab/Epic/40',
  iid: '2',
  title: 'Marketing epic',
  description: 'Mock epic description',
  state: 'opened',
  startDate: '2017-12-25',
  dueDate: '2018-02-15',
  webUrl: 'http://gdk.test:3000/groups/gitlab-org/marketing/-/epics/1',
  hasChildren: false,
  hasParent: false,
  confidential: false,
};

const mockEpicNode2 = {
  __typename: 'Epic',
  parent: null,
  id: 'gid://gitlab/Epic/41',
  iid: '3',
  title: 'Another marketing',
  startDate: '2017-12-26',
  dueDate: '2018-03-10',
  state: 'opened',
  webUrl: 'http://gdk.test:3000/groups/gitlab-org/marketing/-/epics/2',
};

export const mockGroupEpicsQueryResponse = {
  data: {
    group: {
      id: 'gid://gitlab/Group/1',
      name: 'Gitlab Org',
      epics: {
        edges: [
          {
            node: {
              ...mockEpicNode1,
            },
            __typename: 'EpicEdge',
          },
          {
            node: {
              ...mockEpicNode2,
            },
            __typename: 'EpicEdge',
          },
        ],
        __typename: 'EpicConnection',
      },
      __typename: 'Group',
    },
  },
};

export const mockWeightToken = {
  type: 'weight',
  icon: 'weight',
  title: 'Weight',
  unique: true,
  token: WeightToken,
};

export const mockHealthToken = {
  type: 'health',
  icon: 'status-health',
  title: 'Health',
  unique: true,
  operators: OPERATOR_IS_ONLY,
  token: HealthToken,
};
