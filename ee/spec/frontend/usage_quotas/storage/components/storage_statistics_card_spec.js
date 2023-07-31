import { GlProgressBar, GlSkeletonLoader, GlLink } from '@gitlab/ui';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { usageQuotasHelpPaths } from '~/usage_quotas/storage/constants';
import StorageStatisticsCard from 'ee/usage_quotas/storage/components/storage_statistics_card.vue';
import {
  STORAGE_STATISTICS_NAMESPACE_STORAGE_USED,
  STORAGE_STATISTICS_USAGE_QUOTA_LEARN_MORE,
} from 'ee/usage_quotas/storage/constants';
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
      },
    });
  };

  const findCardTitle = () => wrapper.findByTestId('namespace-storage-card-title');
  const findPercentageRemaining = () =>
    wrapper.findByTestId('namespace-storage-percentage-remaining');
  const findProgressBar = () => wrapper.findComponent(GlProgressBar);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);

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

  describe('card title', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the card title', () => {
      expect(findCardTitle().text()).toBe(STORAGE_STATISTICS_NAMESPACE_STORAGE_USED);
    });

    it('renders the help link with the proper attributes', () => {
      expect(findCardTitle().findComponent(GlLink).attributes('href')).toBe(
        usageQuotasHelpPaths.usageQuotas,
      );
      expect(findCardTitle().findComponent(GlLink).attributes('aria-label')).toBe(
        STORAGE_STATISTICS_USAGE_QUOTA_LEARN_MORE,
      );
    });
  });

  describe.each`
    totalStorage | usedStorage  | percentageUsage | percentageRemaining
    ${10}        | ${3}         | ${30}           | ${70}
    ${10}        | ${0}         | ${0}            | ${100}
    ${10}        | ${-1}        | ${0}            | ${100}
    ${10}        | ${undefined} | ${false}        | ${false}
    ${10}        | ${null}      | ${false}        | ${false}
    ${3}         | ${10}        | ${100}          | ${0}
    ${0}         | ${10}        | ${false}        | ${false}
    ${-1}        | ${10}        | ${0}            | ${100}
  `(
    'UI behavior when totalStorage: $totalStorage, usedStorage: $usedStorage',
    ({ totalStorage, usedStorage, percentageUsage, percentageRemaining }) => {
      beforeEach(() => {
        createComponent({ totalStorage, usedStorage });
      });

      it('renders the used and total storage block', () => {
        const usedStorageFormatted =
          usedStorage === 0 || typeof usedStorage !== 'number'
            ? '0'
            : numberToHumanSize(usedStorage);

        const componentText = wrapper.text().replace(/[\s\n]+/g, ' ');

        if (totalStorage === 0) {
          expect(componentText).toContain(` ${usedStorageFormatted}`);
          expect(componentText).not.toContain('/');
        } else {
          expect(componentText).toContain(
            ` ${usedStorageFormatted} / ${numberToHumanSize(totalStorage)}`,
          );
        }
      });

      it(`renders the progress bar as ${percentageUsage}`, () => {
        if (percentageUsage === false) {
          expect(findProgressBar().exists()).toBe(false);
        } else {
          expect(findProgressBar().attributes('value')).toBe(String(percentageUsage));
        }
      });

      it(`renders the percentage remaining as ${percentageRemaining}`, () => {
        if (percentageRemaining === false) {
          expect(findPercentageRemaining().exists()).toBe(false);
        } else {
          expect(findPercentageRemaining().text()).toContain(String(percentageRemaining));
        }
      });
    },
  );
});
