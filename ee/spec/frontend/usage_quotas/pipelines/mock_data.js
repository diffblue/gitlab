import { formatDate } from '~/lib/utils/datetime_utility';
import { TEST_HOST } from 'helpers/test_constants';
import { getProjectMinutesUsage } from 'ee/usage_quotas/pipelines/utils';

export const defaultProvide = {
  namespacePath: 'mygroup',
  namespaceId: '12345',
  userNamespace: false,
  pageSize: '20',
  ciMinutesAnyProjectEnabled: true,
  namespaceActualPlanName: 'MyGroup',
  buyAdditionalMinutesPath: `${TEST_HOST}/-/subscriptions/buy_minutes?selected_group=12345`,
  buyAdditionalMinutesTarget: '_self',
};

export const mockGetNamespaceProjectsInfo = {
  data: {
    namespace: {
      id: 'gid://gitlab/Group/12345',
      projects: {
        nodes: [
          {
            id: 'gid://gitlab/Project/6',
            fullPath: 'flightjs/Flight',
            name: 'Flight',
            nameWithNamespace: 'Flightjs / Flight',
            avatarUrl: null,
            webUrl: 'http://gdk.test:3000/flightjs/Flight',
            __typename: 'Project',
          },
        ],
        pageInfo: {
          __typename: 'PageInfo',
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: 'eyJpZCI6IjYifQ',
          endCursor: 'eyJpZCI6IjYifQ',
        },
        __typename: 'ProjectConnection',
      },
      __typename: 'Namespace',
    },
  },
};

export const mockGetCiMinutesUsageNamespace = {
  data: {
    ciMinutesUsage: {
      nodes: [
        {
          month: 'January',
          monthIso8601: '2015-01-01',
          minutes: 35,
          projects: {
            nodes: [
              {
                name: 'Flight',
                minutes: 35,
                __typename: 'CiMinutesProjectMonthlyUsage',
              },
            ],
            __typename: 'CiMinutesProjectMonthlyUsageConnection',
          },
          __typename: 'CiMinutesNamespaceMonthlyUsage',
        },
      ],
      __typename: 'CiMinutesNamespaceMonthlyUsageConnection',
    },
  },
};

export const defaultProjectListProps = {
  projects: mockGetNamespaceProjectsInfo.data.namespace.projects.nodes.map((project) => ({
    project,
    ci_minutes: getProjectMinutesUsage(
      project,
      mockGetCiMinutesUsageNamespace.data.ciMinutesUsage.nodes.map((node) => ({
        ...node,
        monthIso8601: formatDate(Date.now(), 'yyyy-mm-dd'),
      })),
    ),
  })),
  pageInfo: mockGetNamespaceProjectsInfo.data.namespace.projects.pageInfo,
};
