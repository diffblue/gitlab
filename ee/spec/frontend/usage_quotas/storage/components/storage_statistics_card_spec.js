import { GlProgressBar, GlSkeletonLoader } from '@gitlab/ui';
import StorageStatisticsCard from 'ee/usage_quotas/storage/components/storage_statistics_card.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { statisticsCardDefaultProps } from '../mock_data';

describe('StorageStatisticsCard', () => {
  let wrapper;
  const defaultProps = statisticsCardDefaultProps;
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
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);

  describe('denominator block', () => {
    it('renders denominator block with all elements when all props are passed', () => {
      createComponent();

      expect(findDenominatorBlock().text()).toMatchInterpolatedText('50.0 KiB / 100.0 KiB');
    });

    it('does not render total part of denominator if there is no total passed', () => {
      createComponent({ totalStorage: null });

      expect(findDenominatorBlock().text()).toMatchInterpolatedText('50.0 KiB');
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
    it.each`
      showProgressBar | totalStorage | usedStorage | shouldRender
      ${false}        | ${100}       | ${50}       | ${false}
      ${false}        | ${100}       | ${0}        | ${false}
      ${false}        | ${100}       | ${null}     | ${false}
      ${false}        | ${null}      | ${50}       | ${false}
      ${false}        | ${null}      | ${null}     | ${false}
      ${true}         | ${100}       | ${50}       | ${true}
      ${true}         | ${100}       | ${0}        | ${true}
      ${true}         | ${100}       | ${null}     | ${false}
      ${true}         | ${null}      | ${50}       | ${false}
    `(
      'renders progress bar as $shouldRender when showProgressBar: $showProgressBar, totalStorage: $totalStorage, usedStorage: $usedStorage',
      ({ showProgressBar, totalStorage, usedStorage, shouldRender }) => {
        createComponent({
          showProgressBar,
          totalStorage,
          usedStorage,
        });

        expect(findProgressBar().exists()).toBe(shouldRender);
      },
    );

    it('renders progress bar with correct percentage', () => {
      createComponent({ totalStorage: 10, usedStorage: 5, showProgressBar: true });

      expect(findProgressBar().attributes('value')).toBe(String(50));
    });
  });

  describe('skeleton loader', () => {
    it('renders skeleton loader when loading prop is true', () => {
      createComponent({ loading: true });
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('does not render skeleton loader when loading prop is false', () => {
      createComponent({ loading: false });
      expect(findSkeletonLoader().exists()).toBe(false);
    });
  });
});
