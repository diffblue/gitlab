import { GlLink, GlSprintf, GlProgressBar, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import StorageStatisticsCard from 'ee/usage_quotas/components/storage_statistics_card.vue';
import UsageStatistics from 'ee/usage_quotas/storage/components/usage_statistics.vue';
import { withRootStorageStatistics } from '../mock_data';

describe('UsageStatistics', () => {
  let wrapper;

  const createComponent = ({ props = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(UsageStatistics, {
      propsData: {
        rootStorageStatistics: {
          totalRepositorySize: withRootStorageStatistics.totalRepositorySize,
          actualRepositorySizeLimit: withRootStorageStatistics.actualRepositorySizeLimit,
          totalRepositorySizeExcess: withRootStorageStatistics.totalRepositorySizeExcess,
          additionalPurchasedStorageSize: withRootStorageStatistics.additionalPurchasedStorageSize,
        },
        ...props,
      },
      provide: {
        purchaseStorageUrl: 'some-fancy-url',
        buyAddonTargetAttr: '_self',
        ...provide,
      },
      stubs: {
        StorageStatisticsCard,
        GlSprintf,
        GlLink,
        GlProgressBar,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findAllStorageStatisticsCards = () => wrapper.findAllComponents(StorageStatisticsCard);

  const findNamespaceStorageCard = () => wrapper.findByTestId('namespace-usage-card');
  const findPurchasedStorageCard = () => wrapper.findByTestId('purchased-usage-card');

  describe('with purchaseStorageUrl passed', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders two statistics cards', () => {
      expect(findAllStorageStatisticsCards()).toHaveLength(2);
    });
  });

  describe('with no purchaseStorageUrl', () => {
    beforeEach(() => {
      createComponent({
        provide: {
          purchaseStorageUrl: null,
        },
      });
    });

    it('renders one statistics cards', () => {
      expect(findAllStorageStatisticsCards()).toHaveLength(1);
    });
  });

  describe('namespace storage used', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders progress bar with correct percentage', () => {
      expect(findNamespaceStorageCard().findComponent(GlProgressBar).attributes('value')).toBe(
        '100',
      );
    });
  });

  describe('purchase storage used', () => {
    beforeEach(() => {
      createComponent();
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('renders the denominator and units correctly', () => {
      expect(findPurchasedStorageCard().text().replace(/\s+/g, ' ')).toContain('2.3 KiB / 0.3 KiB');
    });

    it('renders purchase more storage button', () => {
      const purchaseButton = findPurchasedStorageCard().findComponent(GlButton);
      expect(purchaseButton.exists()).toBe(true);
      expect(purchaseButton.attributes('href')).toBe('some-fancy-url');
    });

    it('renders the percentage bar', () => {
      expect(findPurchasedStorageCard().findComponent(GlProgressBar).attributes('value')).toBe(
        '100',
      );
    });
  });

  describe('when limit is exceeded', () => {
    describe('with purchased storage', () => {
      beforeEach(() => {
        createComponent({
          props: {
            rootStorageStatistics: {
              totalRepositorySize: 60 * 1024,
              actualRepositorySizeLimit: 50 * 1024,
              totalRepositorySizeExcess: 1024,
              additionalPurchasedStorageSize: 10 * 1024,
            },
          },
        });
      });

      it('shows only the limit in the namespace storage card', () => {
        expect(findNamespaceStorageCard().text().replace(/\s+/g, ' ')).toContain(
          '50.0 KiB / 50.0 KiB',
        );
      });

      it('shows the excess amount in the purchased storage card', () => {
        expect(findPurchasedStorageCard().text().replace(/\s+/g, ' ')).toContain(
          '1.0 KiB / 10.0 KiB',
        );
      });
    });

    describe('without purchased storage', () => {
      beforeEach(() => {
        createComponent({
          props: {
            rootStorageStatistics: {
              totalRepositorySize: 502642,
              actualRepositorySizeLimit: 500321,
              totalRepositorySizeExcess: 2321,
              additionalPurchasedStorageSize: 0,
            },
          },
        });
      });

      it('shows the total of limit and excess in the namespace storage card', () => {
        expect(findNamespaceStorageCard().text().replace(/\s+/g, ' ')).toContain(
          '490.9 KiB / 488.6 KiB',
        );
      });

      it('shows 0 GiB in the purchased storage card', () => {
        expect(findPurchasedStorageCard().text().replace(/\s+/g, ' ')).toContain('0 GiB');
      });
    });
  });
});
