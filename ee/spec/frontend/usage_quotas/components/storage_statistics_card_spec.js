import { GlProgressBar } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import StorageStatisticsCard from 'ee/usage_quotas/components/storage_statistics_card.vue';

describe('StorageStatisticsCard', () => {
  let wrapper;
  const defaultProps = {
    totalStorage: 100 * 1024,
    usedStorage: 50 * 1024,
  };
  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(StorageStatisticsCard, {
      propsData: { ...defaultProps, ...props },
      slots: {
        description: 'storage-statistics-card description slot',
        actions: 'storage-statistics-card actions slot',
      },
    });
  };

  const findDenominatorBlock = () => wrapper.findByTestId('denominator');
  const findTotalBlock = () => wrapper.findByTestId('denominator-total');
  const findDescriptionBlock = () => wrapper.findByTestId('description');
  const findActionsBlock = () => wrapper.findByTestId('actions');
  const findProgressBar = () => wrapper.findComponent(GlProgressBar);

  describe('denominator block', () => {
    it('renders denominator block with all elements when all props are passed', () => {
      createComponent();

      expect(findDenominatorBlock().text()).toMatchInterpolatedText('50.0 KiB / 100.0 KiB');
    });

    it('does not render total block if totalStorage and usedStorage are not passed', () => {
      createComponent({
        usedStorage: null,
        totalStorage: null,
      });

      expect(findTotalBlock().exists()).toBe(false);
    });

    it('renders the denominator block as 0 GiB if totalStorage and usedStorage are passed as 0', () => {
      createComponent({
        usedStorage: 0,
        totalStorage: 0,
      });

      expect(findDenominatorBlock().text()).toMatchInterpolatedText('0 GiB');
    });
  });

  describe('slots', () => {
    it('renders description slot', () => {
      createComponent();
      expect(findDescriptionBlock().text()).toBe('storage-statistics-card description slot');
    });

    it('renders actions slot', () => {
      createComponent();
      expect(findActionsBlock().text()).toBe('storage-statistics-card actions slot');
    });
  });

  describe('progress bar', () => {
    it('does not render progress bar if there is no totalStorage', () => {
      createComponent({ totalStorage: null });

      expect(wrapper.findComponent(GlProgressBar).exists()).toBe(false);
    });

    it('renders progress bar if percentage is greater than 0', () => {
      createComponent({ totalStorage: 10, usedStorage: 5 });

      expect(findProgressBar().exists()).toBe(true);
      expect(findProgressBar().attributes('value')).toBe(String(50));
    });

    it('renders the progress bar if percentage is 0', () => {
      createComponent({ totalStorage: 10, usedStorage: 0 });
      expect(findProgressBar().exists()).toBe(true);
      expect(findProgressBar().attributes('value')).toBe(String(0));
    });
  });
});
