import { GlProgressBar, GlSkeletonLoader, GlLink } from '@gitlab/ui';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { usageQuotasHelpPaths } from '~/usage_quotas/storage/constants';
import StorageStatisticsCard from 'ee/usage_quotas/storage/components/storage_statistics_card.vue';
import NumberToHumanSize from 'ee/usage_quotas/storage/components/number_to_human_size.vue';
import {
  STORAGE_STATISTICS_NAMESPACE_STORAGE_USED,
  STORAGE_STATISTICS_USAGE_QUOTA_LEARN_MORE,
} from 'ee/usage_quotas/storage/constants';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { statisticsCardDefaultProps, defaultNamespaceProvideValues } from '../mock_data';

describe('StorageStatisticsCard', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;
  const defaultProps = statisticsCardDefaultProps;

  const createComponent = ({ props = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(StorageStatisticsCard, {
      propsData: { ...defaultProps, ...props },
      provide: {
        ...defaultNamespaceProvideValues,
        ...provide,
      },
      stubs: {
        NumberToHumanSize,
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
      createComponent({ props: { loading: true } });
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('does not render skeleton loader when loading prop is false', () => {
      createComponent({ props: { loading: false } });
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
        usageQuotasHelpPaths.usageQuotasProjectStorageLimit,
      );
      expect(findCardTitle().findComponent(GlLink).attributes('aria-label')).toBe(
        STORAGE_STATISTICS_USAGE_QUOTA_LEARN_MORE,
      );
    });
  });

  describe('When under project enforcement', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the card subtitle related to the storage included', () => {
      expect(wrapper.text()).toContain('Storage per project included in Free subscription');
    });

    it('does not render progress bar', () => {
      expect(findProgressBar().exists()).toBe(false);
    });

    it('does not render percentage remaining', () => {
      expect(findPercentageRemaining().exists()).toBe(false);
    });
  });

  describe('When under namespace enforcement', () => {
    it('only renders usedStorage if totalStorage is 0', () => {
      const usedStorage = 1000;

      createComponent({
        props: { totalStorage: 0, usedStorage },
        provide: { isUsingProjectEnforcement: false },
      });

      const componentText = wrapper.text().replace(/[\s\n]+/g, ' ');
      expect(componentText).toContain(numberToHumanSize(usedStorage));
      expect(componentText).not.toContain('/');
    });

    describe.each`
      usedStorage | totalStorage
      ${0}        | ${0}
      ${10}       | ${0}
    `(
      'UI behavior related to percentage usage when totalStorage: $totalStorage, usedStorage: $usedStorage',
      ({ totalStorage, usedStorage }) => {
        beforeEach(() => {
          createComponent({
            props: { totalStorage, usedStorage },
            provide: { isUsingProjectEnforcement: false },
          });
        });

        it('does not render percentage progress bar', () => {
          expect(findProgressBar().exists()).toBe(false);
        });

        it('does not render percentage remaining block', () => {
          expect(findPercentageRemaining().exists()).toBe(false);
        });
      },
    );

    describe.each`
      usedStorage | totalStorage | percentageUsage | percentageRemaining
      ${3}        | ${10}        | ${30}           | ${70}
      ${-1}       | ${10}        | ${0}            | ${100}
      ${10}       | ${3}         | ${100}          | ${0}
      ${10}       | ${-1}        | ${0}            | ${100}
    `(
      'UI behavior when usedStorage: $usedStorage, totalStorage: $totalStorage',
      ({ usedStorage, totalStorage, percentageUsage, percentageRemaining }) => {
        beforeEach(() => {
          createComponent({
            props: { totalStorage, usedStorage },
            provide: { isUsingProjectEnforcement: false },
          });
        });

        it('renders the used and total storage block', () => {
          const componentText = wrapper.text().replace(/[\s\n]+/g, ' ');

          expect(componentText).toContain(
            ` ${numberToHumanSize(usedStorage)} / ${numberToHumanSize(totalStorage)}`,
          );
        });

        it(`renders the progress bar as ${percentageUsage}`, () => {
          expect(findProgressBar().attributes('value')).toBe(String(percentageUsage));
        });

        it(`renders the percentage remaining as ${percentageRemaining}`, () => {
          expect(findPercentageRemaining().text()).toContain(String(percentageRemaining));
        });
      },
    );

    describe('when usedStorage is 0 and totalStorage is bigger than 0', () => {
      const totalStorage = 10;
      const usedStorage = 0;

      beforeEach(() => {
        createComponent({
          props: { totalStorage, usedStorage },
          provide: { isUsingProjectEnforcement: false },
        });
      });

      it('renders the used and total storage block', () => {
        const componentText = wrapper.text().replace(/[\s\n]+/g, ' ');

        expect(componentText).toContain(` 0 / ${numberToHumanSize(totalStorage)}`);
      });

      it('renders the progress bar correctly', () => {
        expect(findProgressBar().attributes('value')).toBe('0');
      });

      it('renders the percentage remaining correctly', () => {
        expect(findPercentageRemaining().text()).toContain('100');
      });
    });
  });
});
