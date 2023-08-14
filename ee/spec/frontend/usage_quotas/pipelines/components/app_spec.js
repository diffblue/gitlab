import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlButton } from '@gitlab/ui';
import { Wrapper } from '@vue/test-utils'; // eslint-disable-line no-unused-vars
import getCiMinutesMonthlySummary from 'ee/usage_quotas/pipelines/graphql/queries/ci_minutes.query.graphql';
import getCiMinutesMonthSummaryWithProjects from 'ee/usage_quotas/pipelines/graphql/queries/ci_minutes_projects.query.graphql';
import { sprintf } from '~/locale';
import { formatDate, getMonthNames } from '~/lib/utils/datetime_utility';
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
  TOTAL_USED_UNLIMITED,
  MINUTES_USED,
  ADDITIONAL_MINUTES,
  PERCENTAGE_USED,
  ADDITIONAL_MINUTES_HELP_LINK,
  CI_MINUTES_HELP_LINK,
  CI_MINUTES_HELP_LINK_LABEL,
} from 'ee/usage_quotas/pipelines/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
import {
  defaultProvide,
  mockGetCiMinutesUsageNamespace,
  mockGetCiMinutesUsageNamespaceProjects,
  emptyMockGetCiMinutesUsageNamespaceProjects,
  defaultProjectListProps,
} from '../mock_data';

Vue.use(VueApollo);
jest.mock('~/google_tag_manager');

describe('PipelineUsageApp', () => {
  /** @type { Wrapper } */
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findOverviewLoadingIcon = () =>
    wrapper.findByTestId('pipelines-overview-loading-indicator');
  const findByMonthChartLoadingIcon = () =>
    wrapper.findByTestId('pipelines-by-month-chart-loading-indicator');
  const findByProjectChartLoadingIcon = () =>
    wrapper.findByTestId('pipelines-by-project-chart-loading-indicator');
  const findProjectList = () => wrapper.findComponent(ProjectList);
  const findBuyAdditionalMinutesButton = () => wrapper.findComponent(GlButton);
  const findMonthlyUsageOverview = () => wrapper.findByTestId('monthly-usage-overview');
  const findPurchasedUsageOverview = () => wrapper.findByTestId('purchased-usage-overview');
  const findYearDropdown = () => wrapper.findComponentByTestId('minutes-usage-year-dropdown');
  const findYearDropdownItems = () =>
    wrapper.findAllComponentsByTestId('minutes-usage-year-dropdown-item');
  const findMonthDropdown = () => wrapper.findComponentByTestId('minutes-usage-month-dropdown');
  const findMonthDropdownItems = () =>
    wrapper.findAllComponentsByTestId('minutes-usage-month-dropdown-item');

  const ciMinutesHandler = jest.fn();
  const ciMinutesProjectsHandler = jest.fn();
  const gqlRejectResponse = new Error('GraphQL error');

  const createMockApolloProvider = () => {
    const requestHandlers = [
      [getCiMinutesMonthlySummary, ciMinutesHandler],
      [getCiMinutesMonthSummaryWithProjects, ciMinutesProjectsHandler],
    ];

    return createMockApollo(requestHandlers);
  };

  const createComponent = ({ provide = {}, mockApollo = createMockApolloProvider() } = {}) => {
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

  beforeEach(() => {
    ciMinutesHandler.mockResolvedValue(mockGetCiMinutesUsageNamespace);
    ciMinutesProjectsHandler.mockResolvedValue(mockGetCiMinutesUsageNamespaceProjects);
  });

  describe('Buy additional compute minutes Button', () => {
    it('calls pushEECproductAddToCartEvent on click', async () => {
      createComponent();

      await waitForPromises();

      findBuyAdditionalMinutesButton().trigger('click');
      expect(pushEECproductAddToCartEvent).toHaveBeenCalledTimes(1);
    });

    describe('Gitlab SaaS: valid data for buyAdditionalMinutesPath and buyAdditionalMinutesTarget', () => {
      it('renders the button to buy additional compute minutes', async () => {
        createComponent();

        await waitForPromises();

        expect(findBuyAdditionalMinutesButton().exists()).toBe(true);
        expect(findBuyAdditionalMinutesButton().text()).toBe(LABEL_BUY_ADDITIONAL_MINUTES);
      });
    });

    describe('Gitlab Self-Managed: buyAdditionalMinutesPath and buyAdditionalMinutesTarget not provided', () => {
      beforeEach(() => {
        createComponent({
          provide: {
            buyAdditionalMinutesPath: undefined,
            buyAdditionalMinutesTarget: undefined,
          },
        });
      });

      it('does not render the button to buy additional compute minutes', () => {
        expect(findBuyAdditionalMinutesButton().exists()).toBe(false);
      });
    });
  });

  describe('namespace ci usage overview', () => {
    it('passes reset date for monthlyUsageTitle to compute minutes UsageOverview if present', async () => {
      createComponent();

      await waitForPromises();

      expect(findMonthlyUsageOverview().props('minutesTitle')).toBe(
        sprintf(TITLE_USAGE_SINCE, {
          usageSince: formatDate(defaultProvide.ciMinutesLastResetDate, 'mmm dd, yyyy', true),
        }),
      );
    });

    it('passes correct props to compute minutes UsageOverview', async () => {
      createComponent();

      await waitForPromises();

      expect(findMonthlyUsageOverview().props()).toMatchObject({
        helpLinkHref: CI_MINUTES_HELP_LINK,
        helpLinkLabel: CI_MINUTES_HELP_LINK_LABEL,
        minutesLimit: defaultProvide.ciMinutesMonthlyMinutesLimit,
        minutesTitle: sprintf(TITLE_USAGE_SINCE, {
          usageSince: formatDate(defaultProvide.ciMinutesLastResetDate, 'mmm dd, yyyy', true),
        }),
        minutesUsed: sprintf(MINUTES_USED, {
          minutesUsed: `${defaultProvide.ciMinutesMonthlyMinutesUsed} / ${defaultProvide.ciMinutesMonthlyMinutesLimit}`,
        }),
        minutesUsedPercentage: sprintf(PERCENTAGE_USED, {
          percentageUsed: defaultProvide.ciMinutesMonthlyMinutesUsedPercentage,
        }),
      });
    });

    it('passes correct props to purchased compute minutes UsageOverview', async () => {
      createComponent();

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

    it('shows unlimited as usagePercentage on compute minutes UsageOverview under correct circumstances', async () => {
      createComponent({
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
      async ({ displayData, purchasedLimit, showAdditionalMinutes }) => {
        createComponent({
          provide: {
            ciMinutesDisplayMinutesAvailableData: displayData,
            ciMinutesPurchasedMinutesLimit: purchasedLimit,
          },
        });
        await waitForPromises();
        const expectedUsageOverviewInstances = showAdditionalMinutes ? 2 : 1;
        expect(wrapper.findAllComponents(UsageOverview)).toHaveLength(
          expectedUsageOverviewInstances,
        );
      },
    );
  });

  describe('with apollo fetching successful', () => {
    it('passes the correct props to ProjectList', async () => {
      createComponent();

      await waitForPromises();

      expect(findProjectList().props()).toMatchObject(defaultProjectListProps);
    });
  });

  describe('with apollo loading', () => {
    beforeEach(() => {
      ciMinutesHandler.mockResolvedValue(null);
      ciMinutesProjectsHandler.mockResolvedValue(null);
      createComponent();
    });

    it('shows loading icon for overview', () => {
      expect(findOverviewLoadingIcon().exists()).toBe(true);
    });

    it('shows a loading icon by month chart', () => {
      expect(findByMonthChartLoadingIcon().exists()).toBe(true);
    });

    it('shows loading icon for by project chart', () => {
      expect(findByProjectChartLoadingIcon().exists()).toBe(true);
    });
  });

  describe('with apollo fetching error', () => {
    beforeEach(() => {
      ciMinutesHandler.mockRejectedValue(gqlRejectResponse);
      createComponent();
      return waitForPromises();
    });

    it('renders failed request error message', () => {
      expect(findAlert().text()).toBe(ERROR_MESSAGE);
    });
  });

  describe('with a namespace without projects', () => {
    beforeEach(() => {
      ciMinutesProjectsHandler.mockResolvedValue(emptyMockGetCiMinutesUsageNamespaceProjects);
      createComponent();
      return waitForPromises();
    });

    it('passes an empty array as projects to ProjectList', () => {
      expect(findProjectList().props('projects')).toEqual([]);
    });
  });

  describe.each`
    pageType          | isUserNamespace | namespaceGQLId
    ${'Namespace'}    | ${false}        | ${convertToGraphQLId(TYPENAME_GROUP, defaultProvide.namespaceId)}
    ${'User profile'} | ${true}         | ${null}
  `('$pageType page type apollo calls', ({ isUserNamespace, namespaceGQLId }) => {
    const defaultPerMonthQueryVariables = {
      date: defaultProvide.ciMinutesLastResetDate,
      first: defaultProvide.pageSize,
      namespaceId: namespaceGQLId,
    };

    beforeEach(async () => {
      createComponent({ provide: { userNamespace: isUserNamespace } });
      await waitForPromises();
    });

    it('sets initial values of Year and Month dropdowns', () => {
      const lastResetDate = new Date(defaultProvide.ciMinutesLastResetDate);
      const expectedYear = lastResetDate.getUTCFullYear().toString();
      const expectedMonth = getMonthNames()[lastResetDate.getUTCMonth()];

      expect(findYearDropdown().props('text')).toBe(expectedYear);
      expect(findMonthDropdown().props('text')).toBe(expectedMonth);
    });

    it('makes monthly initial summary call', () => {
      expect(ciMinutesHandler).toHaveBeenCalledTimes(1);
      expect(ciMinutesHandler).toHaveBeenCalledWith({ namespaceId: namespaceGQLId });
    });

    it('makes month projects initial call', () => {
      expect(ciMinutesProjectsHandler).toHaveBeenCalledTimes(1);
      expect(ciMinutesProjectsHandler).toHaveBeenCalledWith({
        ...defaultPerMonthQueryVariables,
        date: defaultProvide.ciMinutesLastResetDate,
      });
    });

    describe('subsequent calls', () => {
      beforeEach(() => {
        ciMinutesHandler.mockClear();
        ciMinutesProjectsHandler.mockClear();
      });

      it('makes a query to fetch more data when `fetchMore` is emitted', async () => {
        findProjectList().vm.$emit('fetchMore', { after: '123' });
        await nextTick();

        expect(ciMinutesHandler).toHaveBeenCalledTimes(0);
        expect(ciMinutesProjectsHandler).toHaveBeenCalledTimes(1);
        expect(ciMinutesProjectsHandler).toHaveBeenCalledWith({
          after: '123',
          ...defaultPerMonthQueryVariables,
        });
      });

      it('will switch years', async () => {
        const yearItem = findYearDropdownItems().at(1);
        yearItem.vm.$emit('click');
        await nextTick();
        expect(findYearDropdown().props('text')).toBe(yearItem.text());
        expect(ciMinutesHandler).toHaveBeenCalledTimes(0);
        expect(ciMinutesProjectsHandler).toHaveBeenCalledTimes(1);
        expect(ciMinutesProjectsHandler).toHaveBeenCalledWith({
          ...defaultPerMonthQueryVariables,
          date: '2021-08-01',
        });
      });

      it('will switch months', async () => {
        const monthItem = findMonthDropdownItems().at(2);
        monthItem.vm.$emit('click');
        await nextTick();
        expect(findMonthDropdown().props('text')).toBe(monthItem.text());
        expect(ciMinutesHandler).toHaveBeenCalledTimes(0);
        expect(ciMinutesProjectsHandler).toHaveBeenCalledTimes(1);
        expect(ciMinutesProjectsHandler).toHaveBeenCalledWith({
          ...defaultPerMonthQueryVariables,
          date: '2022-03-01',
        });
      });
    });
  });
});
