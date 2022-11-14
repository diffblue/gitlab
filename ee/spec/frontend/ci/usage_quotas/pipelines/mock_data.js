import { sprintf } from '~/locale';
import { TEST_HOST } from 'helpers/test_constants';
import {
  TITLE_USAGE_SINCE,
  MINUTES_USED,
  CI_MINUTES_HELP_LINK,
  CI_MINUTES_HELP_LINK_LABEL,
} from 'ee/ci/usage_quotas/pipelines/constants';

export const defaultProvide = {
  namespacePath: 'mygroup',
  namespaceId: '12345',
  userNamespace: false,
  pageSize: '20',
  ciMinutesAnyProjectEnabled: true,
  ciMinutesDisplayMinutesAvailableData: true,
  ciMinutesLastResetDate: '2022-01-01',
  ciMinutesMonthlyMinutesLimit: '100',
  ciMinutesMonthlyMinutesUsed: '20',
  ciMinutesMonthlyMinutesUsedPercentage: '20',
  ciMinutesPurchasedMinutesLimit: '100',
  ciMinutesPurchasedMinutesUsed: '20',
  ciMinutesPurchasedMinutesUsedPercentage: '20',
  namespaceActualPlanName: 'MyGroup',
  buyAdditionalMinutesPath: `${TEST_HOST}/-/subscriptions/buy_minutes?selected_group=12345`,
  buyAdditionalMinutesTarget: '_self',
};

export const mockGetCiMinutesUsageNamespace = {
  data: {
    ciMinutesUsage: {
      nodes: [
        {
          month: 'January',
          monthIso8601: '2022-01-01',
          minutes: 35,
          sharedRunnersDuration: 120,
          projects: {
            nodes: [
              {
                minutes: 35,
                sharedRunnersDuration: 120,
                project: {
                  id: 'gid://gitlab/Project/6',
                  name: 'Flight',
                  nameWithNamespace: 'Flightjs / Flight',
                  avatarUrl: null,
                  webUrl: 'http://gdk.test:3000/flightjs/Flight',
                  __typename: 'Project',
                },
                __typename: 'CiMinutesProjectMonthlyUsage',
              },
            ],
            pageInfo: {
              __typename: 'PageInfo',
              hasNextPage: false,
              hasPreviousPage: false,
              startCursor: 'eyJpZCI6IjYifQ',
              endCursor: 'eyJpZCI6IjYifQ',
            },
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
  projects: mockGetCiMinutesUsageNamespace.data.ciMinutesUsage.nodes[0].projects.nodes,
  pageInfo: mockGetCiMinutesUsageNamespace.data.ciMinutesUsage.nodes[0].projects.pageInfo,
};

export const defaultUsageOverviewProps = {
  helpLinkHref: CI_MINUTES_HELP_LINK,
  helpLinkLabel: CI_MINUTES_HELP_LINK_LABEL,
  minutesLimit: defaultProvide.ciMinutesMonthlyMinutesLimit,
  minutesTitle: sprintf(TITLE_USAGE_SINCE, {
    usageSince: defaultProvide.ciMinutesLastResetDate,
  }),
  minutesUsed: sprintf(MINUTES_USED, {
    minutesUsed: `${defaultProvide.ciMinutesMonthlyMinutesUsed} / ${defaultProvide.ciMinutesMonthlyMinutesLimit}`,
  }),
  minutesUsedPercentage: defaultProvide.ciMinutesMonthlyMinutesUsedPercentage,
};
