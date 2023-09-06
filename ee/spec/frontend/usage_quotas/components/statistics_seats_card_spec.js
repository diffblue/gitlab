import { GlLink } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import StatisticsSeatsCard from 'ee/usage_quotas/seats/components/statistics_seats_card.vue';
import Tracking from '~/tracking';
import { visitUrl } from '~/lib/utils/url_utility';
import LimitedAccessModal from 'ee/usage_quotas/components/limited_access_modal.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn().mockName('visitUrlMock'),
}));

describe('StatisticsSeatsCard', () => {
  let wrapper;
  const purchaseButtonLink = 'https://gitlab.com/purchase-more-seats';
  const defaultProps = {
    seatsUsed: 20,
    seatsOwed: 5,
    purchaseButtonLink,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(StatisticsSeatsCard, {
      propsData: { ...defaultProps, ...props },
      stubs: {
        LimitedAccessModal,
      },
    });
  };

  const findSeatsUsedBlock = () => wrapper.findByTestId('seats-used');
  const findSeatsOwedBlock = () => wrapper.findByTestId('seats-owed');
  const findPurchaseButton = () => wrapper.findByTestId('purchase-button');
  const findLimitedAccessModal = () => wrapper.findComponent(LimitedAccessModal);

  describe('seats used block', () => {
    it('renders seats used block if seatsUsed is passed', () => {
      createComponent();

      const seatsUsedBlock = findSeatsUsedBlock();

      expect(seatsUsedBlock.exists()).toBe(true);
      expect(seatsUsedBlock.text()).toContain('20');
      expect(seatsUsedBlock.findComponent(GlLink).exists()).toBe(true);
    });

    it('does not render seats used block if seatsUsed is not passed', () => {
      createComponent({ seatsUsed: null });

      expect(findSeatsUsedBlock().exists()).toBe(false);
    });
  });

  describe('seats owed block', () => {
    it('renders seats owed block if seatsOwed is passed', () => {
      createComponent();

      const seatsOwedBlock = findSeatsOwedBlock();

      expect(seatsOwedBlock.exists()).toBe(true);
      expect(seatsOwedBlock.text()).toContain('5');
      expect(seatsOwedBlock.findComponent(GlLink).exists()).toBe(true);
    });

    it('does not render seats owed block if seatsOwed is not passed', () => {
      createComponent({ seatsOwed: null });

      expect(findSeatsOwedBlock().exists()).toBe(false);
    });
  });

  describe('purchase button', () => {
    it('renders purchase button if purchase link and purchase text is passed', () => {
      createComponent();

      const purchaseButton = findPurchaseButton();

      expect(purchaseButton.exists()).toBe(true);
    });

    it('does not render purchase button if purchase link is not passed', () => {
      createComponent({ purchaseButtonLink: null });

      expect(findPurchaseButton().exists()).toBe(false);
    });

    it('tracks event', () => {
      jest.spyOn(Tracking, 'event');
      createComponent();
      findPurchaseButton().vm.$emit('click');

      expect(Tracking.event).toHaveBeenCalledWith(undefined, 'click_button', {
        label: 'add_seats_saas',
        property: 'usage_quotas_page',
      });
    });

    it('redirects when clicked', () => {
      createComponent();
      findPurchaseButton().vm.$emit('click');

      expect(visitUrl).toHaveBeenCalledWith('https://gitlab.com/purchase-more-seats');
    });
  });

  describe('limited access modal', () => {
    afterEach(() => {
      jest.restoreAllMocks();
    });

    describe('when limitedAccessModal FF is on', () => {
      beforeEach(async () => {
        gon.features = { limitedAccessModal: true };
        createComponent();

        findPurchaseButton().vm.$emit('click');
        await nextTick();
      });

      it('shows modal', () => {
        expect(findLimitedAccessModal().isVisible()).toBe(true);
      });

      it('does not navigate to URL', () => {
        expect(visitUrl).not.toHaveBeenCalled();
      });
    });

    describe('when limitedAccessModal FF is off', () => {
      beforeEach(async () => {
        gon.features = { limitedAccessModal: false };
        createComponent();

        findPurchaseButton().vm.$emit('click');
        await nextTick();
      });

      it('does not show modal', () => {
        expect(findLimitedAccessModal().exists()).toBe(false);
      });

      it('navigates to URL', () => {
        expect(visitUrl).toHaveBeenCalledWith('https://gitlab.com/purchase-more-seats');
      });
    });
  });
});
