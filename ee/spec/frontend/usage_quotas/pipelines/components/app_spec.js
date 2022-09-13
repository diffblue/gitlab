import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlButton, GlLoadingIcon } from '@gitlab/ui';
import { formatDate } from '~/lib/utils/datetime_utility';
import { sprintf } from '~/locale';
import { pushEECproductAddToCartEvent } from '~/google_tag_manager';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import PipelineUsageApp from 'ee/usage_quotas/pipelines/components/app.vue';
import ProjectList from 'ee/usage_quotas/pipelines/components/project_list.vue';
import UsageOverview from 'ee/usage_quotas/pipelines/components/usage_overview.vue';
import {
  LABEL_BUY_ADDITIONAL_MINUTES,
  ERROR_MESSAGE,
  TITLE_USAGE_SINCE,
  TITLE_CURRENT_PERIOD,
  TOTAL_USED_UNLIMITED,
  MINUTES_USED,
  ADDITIONAL_MINUTES,
  PERCENTAGE_USED,
  ADDITIONAL_MINUTES_HELP_LINK,
  CI_MINUTES_HELP_LINK,
  CI_MINUTES_HELP_LINK_LABEL,
} from 'ee/usage_quotas/pipelines/constants';
import getNamespaceProjectsInfo from 'ee/usage_quotas/pipelines/queries/namespace_projects_info.query.graphql';
import getCiMinutesUsageNamespace from 'ee/usage_quotas/ci_minutes_usage/graphql/queries/ci_minutes_namespace.query.graphql';
import {
  defaultProvide,
  mockGetNamespaceProjectsInfo,
  mockGetCiMinutesUsageNamespace,
} from '../mock_data';

Vue.use(VueApollo);
jest.mock('~/google_tag_manager');

describe('PipelineUsageApp', () => {
  let wrapper;

  const createMockApolloProvider = ({
    reject = false,
    mockNamespaceProject = mockGetNamespaceProjectsInfo,
    mockCiMinutesUsageQuery = mockGetCiMinutesUsageNamespace,
  } = {}) => {
    const rejectResponse = jest.fn().mockRejectedValue(new Error('GraphQL error'));
    const requestHandlers = [
      [
        getNamespaceProjectsInfo,
        reject ? rejectResponse : jest.fn().mockResolvedValue(mockNamespaceProject),
      ],
      [
        getCiMinutesUsageNamespace,
        reject ? rejectResponse : jest.fn().mockResolvedValue(mockCiMinutesUsageQuery),
      ],
    ];

    return createMockApollo(requestHandlers);
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findProjectList = () => wrapper.findComponent(ProjectList);
  const findBuyAdditionalMinutesButton = () => wrapper.findComponent(GlButton);
  const findMonthlyUsageOverview = () => wrapper.findByTestId('monthly-usage-overview');
  const findPurchasedUsageOverview = () => wrapper.findByTestId('purchased-usage-overview');

  const createComponent = ({ provide = {}, mockApollo } = {}) => {
    wrapper = shallowMountExtended(PipelineUsageApp, {
      apolloProvider: mockApollo,
      provide: {
        ...defaultProvide,
        ...provide,
      },
      stubs: {
        GlButton,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Buy additional minutes Button', () => {
    const mockApollo = createMockApolloProvider();

    it('calls pushEECproductAddToCartEvent on click', async () => {
      createComponent({ mockApollo });

      await waitForPromises();

      findBuyAdditionalMinutesButton().trigger('click');
      expect(pushEECproductAddToCartEvent).toHaveBeenCalledTimes(1);
    });

    describe('Gitlab SaaS: valid data for buyAdditionalMinutesPath and buyAdditionalMinutesTarget', () => {
      it('renders the button to buy additional minutes', async () => {
        createComponent({ mockApollo });

        await waitForPromises();

        expect(findBuyAdditionalMinutesButton().exists()).toBe(true);
        expect(findBuyAdditionalMinutesButton().text()).toBe(LABEL_BUY_ADDITIONAL_MINUTES);
      });
    });

    describe('Gitlab Self-Managed: buyAdditionalMinutesPath and buyAdditionalMinutesTarget not provided', () => {
      beforeEach(() => {
        createComponent({
          mockApollo,
          provide: {
            buyAdditionalMinutesPath: undefined,
            buyAdditionalMinutesTarget: undefined,
          },
        });
      });

      it('does not render the button to buy additional minutes', () => {
        expect(findBuyAdditionalMinutesButton().exists()).toBe(false);
      });
    });
  });

  describe('namespace ci usage overview', () => {
    const mockApollo = createMockApolloProvider();

    it('passes reset date for monthlyUsageTitle to minutes UsageOverview if present', async () => {
      createComponent({ mockApollo });

      await waitForPromises();

      expect(findMonthlyUsageOverview().props('minutesTitle')).toBe(
        sprintf(TITLE_USAGE_SINCE, {
          usageSince: defaultProvide.ciMinutesLastResetDate,
        }),
      );
    });

    it('passes current period for monthlyUsageTitle to minutes UsageOverview if no reset date', async () => {
      createComponent({ mockApollo, provide: { ciMinutesLastResetDate: '' } });

      await waitForPromises();

      expect(findMonthlyUsageOverview().props('minutesTitle')).toBe(TITLE_CURRENT_PERIOD);
    });

    it('passes correct props to minutes UsageOverview', async () => {
      createComponent({ mockApollo });

      await waitForPromises();

      expect(findMonthlyUsageOverview().props()).toMatchObject({
        helpLinkHref: CI_MINUTES_HELP_LINK,
        helpLinkLabel: CI_MINUTES_HELP_LINK_LABEL,
        minutesLimit: defaultProvide.ciMinutesMonthlyMinutesLimit,
        minutesTitle: sprintf(TITLE_USAGE_SINCE, {
          usageSince: defaultProvide.ciMinutesLastResetDate,
        }),
        minutesUsed: sprintf(MINUTES_USED, {
          minutesUsed: `${defaultProvide.ciMinutesMonthlyMinutesUsed} / ${defaultProvide.ciMinutesMonthlyMinutesLimit}`,
        }),
        minutesUsedPercentage: sprintf(PERCENTAGE_USED, {
          percentageUsed: defaultProvide.ciMinutesMonthlyMinutesUsedPercentage,
        }),
      });
    });

    it('passes correct props to purchased minutes UsageOverview', async () => {
      createComponent({ mockApollo });

      await waitForPromises();

      expect(findPurchasedUsageOverview().props()).toMatchObject({
        helpLinkHref: ADDITIONAL_MINUTES_HELP_LINK,
        helpLinkLabel: ADDITIONAL_MINUTES,
        minutesLimit: defaultProvide.ciMinutesMonthlyMinutesLimit,
        minutesTitle: ADDITIONAL_MINUTES,
        minutesUsed: sprintf(MINUTES_USED, {
          minutesUsed: `${defaultProvide.ciMinutesPurchasedMinutesUsed} / ${defaultProvide.ciMinutesPurchasedMinutesLimit}`,
        }),
        minutesUsedPercentage: sprintf(PERCENTAGE_USED, {
          percentageUsed: defaultProvide.ciMinutesPurchasedMinutesUsedPercentage,
        }),
      });
    });

    it('shows unlimited as usagePercentage on minutes UsageOverview under correct circumstances', async () => {
      createComponent({
        mockApollo,
        provide: {
          ciMinutesDisplayMinutesAvailableData: false,
          ciMinutesAnyProjectEnabled: false,
        },
      });

      await waitForPromises();

      expect(findMonthlyUsageOverview().props('minutesUsedPercentage')).toBe(TOTAL_USED_UNLIMITED);
    });

    it.each`
      displayData | purchasedLimit | showAdditionalMinutes
      ${true}     | ${'100'}       | ${true}
      ${true}     | ${'0'}         | ${false}
      ${false}    | ${'100'}       | ${false}
      ${false}    | ${'0'}         | ${false}
    `(
      'shows additional minutes: $showAdditionalMinutes when displayData is $displayData and purchase limit is $purchasedLimit',
      ({ displayData, purchasedLimit, showAdditionalMinutes }) => {
        createComponent({
          mockApollo,
          provide: {
            ciMinutesDisplayMinutesAvailableData: displayData,
            ciMinutesPurchasedMinutesLimit: purchasedLimit,
          },
        });
        const expectedUsageOverviewInstances = showAdditionalMinutes ? 2 : 1;
        expect(wrapper.findAllComponents(UsageOverview).length).toBe(
          expectedUsageOverviewInstances,
        );
      },
    );
  });

  describe('with apollo fetching successful', () => {
    beforeEach(() => {
      const mockCiMinutesUsageQuery = { ...mockGetCiMinutesUsageNamespace };
      mockCiMinutesUsageQuery.data.ciMinutesUsage.nodes[0].monthIso8601 = formatDate(
        Date.now(),
        'yyyy-mm-dd',
      );

      const mockApollo = createMockApolloProvider({
        mockCiMinutesUsageQuery,
      });
      createComponent({ mockApollo });
      return waitForPromises();
    });

    it('passes the correct props to ProjectList', () => {
      expect(findProjectList().props()).toMatchObject({
        pageInfo: {
          endCursor: 'eyJpZCI6IjYifQ',
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: 'eyJpZCI6IjYifQ',
        },
        projects: [
          {
            ci_minutes: mockGetCiMinutesUsageNamespace.data.ciMinutesUsage.nodes[0].minutes,
            project: {
              avatarUrl: null,
              fullPath: 'flightjs/Flight',
              id: 'gid://gitlab/Project/6',
              name: 'Flight',
              nameWithNamespace: 'Flightjs / Flight',
              webUrl: 'http://gdk.test:3000/flightjs/Flight',
            },
          },
        ],
      });
    });
  });

  describe('with apollo loading', () => {
    beforeEach(() => {
      const mockApollo = createMockApolloProvider({
        mockCiMinutesUsageQuery: new Promise(() => {}),
      });
      createComponent({ mockApollo });
    });

    it('should show loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('with apollo fetching error', () => {
    beforeEach(() => {
      const mockApollo = createMockApolloProvider({ reject: true });
      createComponent({ mockApollo });
      return waitForPromises();
    });

    it('renders failed request error message', () => {
      expect(findAlert().text()).toBe(ERROR_MESSAGE);
    });
  });

  describe('with a namespace without projects', () => {
    beforeEach(() => {
      const mockNamespaceProject = { ...mockGetNamespaceProjectsInfo };
      mockNamespaceProject.data.namespace.projects.nodes = [];

      const mockApollo = createMockApolloProvider({
        mockNamespaceProject,
      });
      createComponent({ mockApollo });
      return waitForPromises();
    });

    it('passes an empty array as projects to ProjectList', () => {
      expect(findProjectList().props('projects')).toEqual([]);
    });
  });

  describe('apollo calls', () => {
    beforeEach(() => {
      const mockApollo = createMockApolloProvider();
      createComponent({ mockApollo });
      return waitForPromises();
    });

    it('makes a query to fetch more data when `fetchMore` is emitted', async () => {
      jest
        .spyOn(wrapper.vm.$apollo.queries.namespace, 'fetchMore')
        .mockImplementation(jest.fn().mockResolvedValue());

      findProjectList().vm.$emit('fetchMore');
      await nextTick();

      expect(wrapper.vm.$apollo.queries.namespace.fetchMore).toHaveBeenCalledTimes(1);
    });
  });
});
