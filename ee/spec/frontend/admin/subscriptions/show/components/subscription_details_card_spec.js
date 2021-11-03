import { GlCard } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { subscriptionDetailsFields } from 'ee/admin/subscriptions/show/components/subscription_breakdown.vue';
import SubscriptionDetailsCard from 'ee/admin/subscriptions/show/components/subscription_details_card.vue';
import SubscriptionDetailsTable from 'ee/admin/subscriptions/show/components/subscription_details_table.vue';
import { useFakeDate } from 'helpers/fake_date';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { license } from '../mock_data';

describe('Subscription Details Card', () => {
  // March 16th, 2020
  useFakeDate(2021, 2, 16);

  let wrapper;

  const findCard = () => wrapper.findComponent(GlCard);
  const findCardHeader = () => findCard().find('.gl-card-header');
  const findCardFooter = () => findCard().find('.gl-card-footer');
  const findSubscriptionDetailsTable = () => wrapper.findComponent(SubscriptionDetailsTable);

  const createComponent = (props = {}, slots) => {
    wrapper = extendedWrapper(
      shallowMount(SubscriptionDetailsCard, {
        propsData: {
          detailsFields: subscriptionDetailsFields,
          subscription: license.ULTIMATE,
          ...props,
        },
        stubs: {
          GlCard,
        },
        slots,
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with data', () => {
    beforeEach(() => {
      createComponent({
        headerText: 'Card header title',
      });
    });

    it('displays a title', () => {
      expect(findCard().text()).toBe('Card header title');
    });

    it('displays the details table component', () => {
      expect(findSubscriptionDetailsTable().exists()).toBe(true);
    });

    it('passes the details to the table component', () => {
      expect(findSubscriptionDetailsTable().props('details')).toEqual([
        {
          detail: 'id',
          value: 13,
        },
        {
          detail: 'plan',
          value: 'Ultimate',
        },
        {
          detail: 'expiresAt',
          value: 'in 1 year',
        },
        {
          detail: 'lastSync',
          value: 'just now',
        },
        {
          detail: 'startsAt',
          value: '2021-03-11',
        },
      ]);
    });
  });

  describe('subscription sync state', () => {
    it('passes true when sync succeeded', () => {
      createComponent({ syncDidFail: false });

      expect(findSubscriptionDetailsTable().props('syncDidFail')).toBe(false);
    });

    it('passes true when sync failed', () => {
      createComponent({ syncDidFail: true });

      expect(findSubscriptionDetailsTable().props('syncDidFail')).toBe(true);
    });
  });

  describe('with no title', () => {
    it('does not display a title', () => {
      createComponent();

      expect(findCardHeader().exists()).toBe(false);
    });
  });

  describe('with footer', () => {
    beforeEach(() => {
      createComponent(
        {},
        {
          footer: '<div>Footer content</div>',
        },
      );
    });

    it('displays the footer', () => {
      expect(findCardFooter().exists()).toBe(true);
    });

    it('displays the footer text', () => {
      expect(findCardFooter().text()).toContain('Footer content');
    });
  });
});
