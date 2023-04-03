import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import GroupTransferApp from 'ee/usage_quotas/transfer/components/group_transfer_app.vue';
import UsageByMonth from 'ee/usage_quotas/transfer/components/usage_by_month.vue';
import UsageByProject from 'ee/usage_quotas/transfer/components/usage_by_project.vue';
import StatisticsCard from 'ee/usage_quotas/components/statistics_card.vue';
import getGroupDataTransferEgress from 'ee/usage_quotas/transfer/graphql/queries/get_group_data_transfer_egress.query.graphql';
import { DEFAULT_PER_PAGE } from '~/api';
import { getGroupDataTransferEgressResponse } from '../mock_data';

describe('GroupTransferApp', () => {
  let wrapper;

  const defaultProvide = {
    fullPath: 'h5bp',
  };

  const defaultRequestHandler = () =>
    jest.fn().mockResolvedValueOnce(getGroupDataTransferEgressResponse);

  const createComponent = ({
    provide = {},
    requestHandlers = [[getGroupDataTransferEgress, defaultRequestHandler()]],
  } = {}) => {
    Vue.use(VueApollo);

    wrapper = shallowMountExtended(GroupTransferApp, {
      provide: { ...defaultProvide, ...provide },
      apolloProvider: createMockApollo(requestHandlers),
    });
  };

  const findStatisticsCard = () => wrapper.findComponent(StatisticsCard);
  const findGlALert = () => wrapper.findComponent(GlAlert);
  const findUsageByMonth = () => wrapper.findComponent(UsageByMonth);
  const findUsageByProject = () => wrapper.findComponent(UsageByProject);

  describe('when GraphQL request is loading', () => {
    beforeEach(() => {
      createComponent({
        requestHandlers: [
          [getGroupDataTransferEgress, jest.fn().mockReturnValueOnce(new Promise(() => {}))],
        ],
      });
    });

    it('sets `StatisticsCard` `loading` prop to `true`', () => {
      expect(findStatisticsCard().props('loading')).toBe(true);
    });

    it('sets `UsageByMonth` `loading` prop to `true`', () => {
      expect(findUsageByMonth().props('loading')).toBe(true);
    });

    it('sets `UsageByProject` `loading` prop to `true`', () => {
      expect(findUsageByProject().props('loading')).toBe(true);
    });
  });

  describe('when GraphQL request is successful', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it('renders `StatisticsCard` component and correctly passes props', () => {
      expect(findStatisticsCard().props()).toMatchObject({
        usageValue: '19.63',
        usageUnit: 'GiB',
        totalValue: GroupTransferApp.i18n.STATISTICS_CARD_TOTAL_VALUE,
        description: GroupTransferApp.i18n.STATISTICS_CARD_DESCRIPTION,
        loading: false,
      });
    });

    it('renders `UsageByMonth` component and correctly passes props', () => {
      expect(findUsageByMonth().props()).toMatchObject({
        chartData: [
          ['Jan 2023', '5000861558'],
          ['Feb 2023', '6651307793'],
          ['Mar 2023', '5368547376'],
          ['Apr 2023', '4055795925'],
        ],
        loading: false,
      });
    });

    it('renders `UsageByProject` component and correctly passes props', () => {
      expect(findUsageByProject().props()).toMatchObject({
        projects: getGroupDataTransferEgressResponse.data.group.projects,
        loading: false,
      });
    });
  });

  describe('when `UsageByProject` component emits `next` event', () => {
    it('calls GraphQL request with correct variables', async () => {
      const requestHandler = defaultRequestHandler().mockResolvedValueOnce(
        getGroupDataTransferEgressResponse,
      );
      createComponent({
        requestHandlers: [[getGroupDataTransferEgress, requestHandler]],
      });
      await waitForPromises();

      const { endCursor } = getGroupDataTransferEgressResponse.data.group.projects.pageInfo;

      findUsageByProject().vm.$emit('next', endCursor);
      await waitForPromises();

      expect(requestHandler).toHaveBeenLastCalledWith({
        first: DEFAULT_PER_PAGE,
        after: endCursor,
        last: null,
        before: null,
        fullPath: defaultProvide.fullPath,
      });
    });
  });

  describe('when `UsageByProject` component emits `prev` event', () => {
    it('calls GraphQL request with correct variables', async () => {
      const requestHandler = defaultRequestHandler().mockResolvedValueOnce(
        getGroupDataTransferEgressResponse,
      );
      createComponent({
        requestHandlers: [[getGroupDataTransferEgress, requestHandler]],
      });
      await waitForPromises();

      const { startCursor } = getGroupDataTransferEgressResponse.data.group.projects.pageInfo;

      findUsageByProject().vm.$emit('prev', startCursor);
      await waitForPromises();

      expect(requestHandler).toHaveBeenLastCalledWith({
        first: null,
        after: null,
        last: DEFAULT_PER_PAGE,
        before: startCursor,
        fullPath: defaultProvide.fullPath,
      });
    });
  });

  describe('when GraphQL request is not successful', () => {
    beforeEach(async () => {
      createComponent({
        requestHandlers: [[getGroupDataTransferEgress, jest.fn().mockRejectedValueOnce()]],
      });

      await waitForPromises();
    });

    it('shows error alert', () => {
      expect(findGlALert().text()).toBe(GroupTransferApp.i18n.ERROR_MESSAGE);
    });

    it('allows error alert to be closed', async () => {
      findGlALert().vm.$emit('dismiss');
      await nextTick();

      expect(findGlALert().exists()).toBe(false);
    });
  });
});
