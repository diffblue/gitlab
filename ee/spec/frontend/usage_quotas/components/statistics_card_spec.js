import { GlLink, GlButton, GlProgressBar, GlSkeletonLoader } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import StatisticsCard from 'ee/usage_quotas/components/statistics_card.vue';

describe('StatisticsCard', () => {
  let wrapper;
  const defaultProps = {
    description: 'Dummy text for description',
    helpLink: 'http://test.gitlab.com/',
    purchaseButtonLink: 'http://gitlab.com/purchase',
    purchaseButtonText: 'Purchase more storage',
    percentage: 75,
    usageValue: '1,000',
    usageUnit: 'MiB',
    totalValue: '10,000',
    totalUnit: 'MiB',
  };
  const createComponent = (props = {}) => {
    wrapper = shallowMount(StatisticsCard, {
      propsData: props,
    });
  };

  const findDenominatorBlock = () => wrapper.find('[data-testid="denominator"]');
  const findUsageUnitBlock = () => wrapper.find('[data-testid="denominator-usage-unit"]');
  const findTotalBlock = () => wrapper.find('[data-testid="denominator-total"]');
  const findTotalUnitBlock = () => wrapper.find('[data-testid="denominator-total-unit"]');
  const findDescriptionBlock = () => wrapper.find('[data-testid="description"]');
  const findPurchaseButton = () => wrapper.findComponent(GlButton);
  const findHelpLink = () => wrapper.findComponent(GlLink);
  const findProgressBar = () => wrapper.findComponent(GlProgressBar);

  it('passes cssClass to container div', () => {
    const cssClass = 'awesome-css-class';
    createComponent({ cssClass });
    expect(wrapper.find('[data-testid="container"]').classes()).toContain(cssClass);
  });

  describe('denominator block', () => {
    it('renders denominator block with all elements when all props are passed', () => {
      createComponent(defaultProps);

      expect(findDenominatorBlock().html()).toMatchSnapshot();
    });

    it('hides denominator block if usageValue is not passed', () => {
      createComponent({
        usageValue: null,
        usageUnit: 'minutes',
        totalUsage: '1,000',
        totalUnit: 'minutes',
      });
      expect(findDenominatorBlock().exists()).toBe(false);
    });

    it('does not render usage unit if usageUnit is not passed', () => {
      createComponent({
        usageValue: '1,000',
        usageUnit: null,
        totalUsage: '1,000',
        totalUnit: 'minutes',
      });

      expect(findUsageUnitBlock().exists()).toBe(false);
    });

    it('does not render total block if totalValue is not passed', () => {
      createComponent({
        usageValue: '1,000',
        usageUnit: 'minutes',
        totalUsage: null,
        totalUnit: 'minutes',
      });

      expect(findTotalBlock().exists()).toBe(false);
    });

    it('does not render total unit if totalUnit is not passed', () => {
      createComponent({
        usageValue: '1,000',
        usageUnit: 'minutes',
        totalUsage: '1,000',
        totalUnit: null,
      });

      expect(findTotalUnitBlock().exists()).toBe(false);
    });
  });

  describe('description block', () => {
    it('does not render description if prop is not passed', () => {
      createComponent({ description: null });
      expect(findDescriptionBlock().exists()).toBe(false);
    });

    it('renders help link if description and helpLink props are passed', () => {
      const description = 'description value';
      const helpLink = 'https://docs.gitlab.com';
      const helpTooltip = 'Tooltip text';

      createComponent({ description, helpLink, helpTooltip });

      expect(findDescriptionBlock().text()).toBe(description);
      expect(findHelpLink().attributes('href')).toBe(helpLink);
      expect(findHelpLink().attributes('title')).toBe(helpTooltip);
    });

    it('does not render help link if prop is not passed', () => {
      createComponent({ helpLink: null });
      expect(wrapper.findComponent(GlLink).exists()).toBe(false);
    });
  });

  describe('purchase button', () => {
    const purchaseButtonLink = 'http://gitlab.com/purchase';
    const purchaseButtonText = 'Purchase more storage';

    it('renders purchase button if purchase link and text props are passed', () => {
      createComponent({ purchaseButtonLink, purchaseButtonText });

      expect(findPurchaseButton().text()).toBe(purchaseButtonText);
      expect(findPurchaseButton().attributes('href')).toBe(purchaseButtonLink);
    });

    it('does not render purchase button if purchase link is not passed', () => {
      createComponent({ purchaseButtonText });

      expect(findPurchaseButton().exists()).toBe(false);
    });

    it('does not render purchase button if purchase text is not passed', () => {
      createComponent({ purchaseButtonLink });

      expect(findPurchaseButton().exists()).toBe(false);
    });
  });

  describe('progress bar', () => {
    it('does not render progress bar if prop is not passed', () => {
      createComponent({ percentage: null });

      expect(wrapper.findComponent(GlProgressBar).exists()).toBe(false);
    });

    it('renders progress bar if prop is greater than 0', () => {
      const percentage = 99;
      createComponent({ percentage });

      expect(findProgressBar().exists()).toBe(true);
      expect(findProgressBar().attributes('value')).toBe(String(percentage));
    });

    it('renders the progress bar if prop is 0', () => {
      const percentage = 0;
      createComponent({ percentage });

      expect(findProgressBar().exists()).toBe(true);
      expect(findProgressBar().attributes('value')).toBe(String(percentage));
    });
  });

  describe('when `loading` prop is `true`', () => {
    beforeEach(() => {
      createComponent({ ...defaultProps, loading: true });
    });

    it('renders `GlSkeletonLoader`', () => {
      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
    });
  });
});
