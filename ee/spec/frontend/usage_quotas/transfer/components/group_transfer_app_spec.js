import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import GroupTransferApp from 'ee/usage_quotas/transfer/components/group_transfer_app.vue';
import StatisticsCard from 'ee/usage_quotas/components/statistics_card.vue';
import getGroupDataTransferEgress from 'ee/usage_quotas/transfer/graphql/queries/get_group_data_transfer_egress.query.graphql';
import { USAGE_BY_MONTH_HEADER, USAGE_BY_PROJECT_HEADER } from 'ee/usage_quotas/constants';
import { getGroupDataTransferEgressResponse } from '../mock_data';

describe('GroupTransferApp', () => {
  let wrapper;

  const defaultProvide = {
    fullPath: 'h5bp',
  };

  const createComponent = ({
    provide = {},
    requestHandlers = [
      [
        getGroupDataTransferEgress,
        jest.fn().mockResolvedValueOnce(getGroupDataTransferEgressResponse),
      ],
    ],
  } = {}) => {
    Vue.use(VueApollo);

    wrapper = shallowMountExtended(GroupTransferApp, {
      provide: { ...defaultProvide, ...provide },
      apolloProvider: createMockApollo(requestHandlers),
    });
  };

  const findStatisticsCard = () => wrapper.findComponent(StatisticsCard);
  const findGlALert = () => wrapper.findComponent(GlAlert);

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

  it('renders `Usage by month` heading', () => {
    createComponent();

    expect(wrapper.findByRole('heading', { name: USAGE_BY_MONTH_HEADER }).exists()).toBe(true);
  });

  it('renders `Usage by project` heading', () => {
    createComponent();

    expect(wrapper.findByRole('heading', { name: USAGE_BY_PROJECT_HEADER }).exists()).toBe(true);
  });
});
