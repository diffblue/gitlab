import { GlLink, GlSprintf, GlProgressBar, GlButton } from '@gitlab/ui';
import StorageStatisticsCard from 'ee/usage_quotas/storage/components/storage_statistics_card.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { projectHelpPaths } from '~/usage_quotas/storage/constants';
import StorageUsageStatistics from 'ee/usage_quotas/storage/components/storage_usage_statistics.vue';

import { withRootStorageStatistics } from '../mock_data';

describe('StorageUsageStatistics', () => {
  let wrapper;

  const createComponent = ({ props = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(StorageUsageStatistics, {
      propsData: {
        totalRepositorySize: withRootStorageStatistics.totalRepositorySize,
        actualRepositorySizeLimit: withRootStorageStatistics.actualRepositorySizeLimit,
        totalRepositorySizeExcess: withRootStorageStatistics.totalRepositorySizeExcess,
        additionalPurchasedStorageSize: withRootStorageStatistics.additionalPurchasedStorageSize,
        storageLimitEnforced: true,
        loading: false,
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

  const findNamespaceStorageCard = () => wrapper.findByTestId('namespace-usage-card');
  const findPurchasedStorageCard = () => wrapper.findByTestId('purchased-usage-card');

  describe('namespace storage card', () => {
    it('renders card description with help link', () => {
      createComponent();

      expect(findNamespaceStorageCard().text()).toContain('Namespace storage used');
      expect(findNamespaceStorageCard().findComponent(GlLink).exists()).toBe(true);
    });

    it('uses repository size limit when usage is greater than repository size limit', () => {
      createComponent();

      expect(findNamespaceStorageCard().props()).toEqual({
        loading: false,
        showProgressBar: true,
        totalStorage: withRootStorageStatistics.totalRepositorySize,
        usedStorage: withRootStorageStatistics.actualRepositorySizeLimit,
      });
    });

    it('passes the correct props when storageLimitEnforced is true', () => {
      createComponent({ props: { storageLimitEnforced: true } });

      expect(findNamespaceStorageCard().props()).toEqual({
        loading: false,
        showProgressBar: true,
        totalStorage: withRootStorageStatistics.totalRepositorySize,
        usedStorage: withRootStorageStatistics.totalRepositorySize,
      });
    });

    it('passes the correct props when storageLimitEnforced is false', () => {
      createComponent({ props: { storageLimitEnforced: false } });

      expect(findNamespaceStorageCard().props()).toEqual({
        loading: false,
        showProgressBar: false,
        totalStorage: null,
        usedStorage: withRootStorageStatistics.totalRepositorySize,
      });
    });

    describe('additional storage purchased', () => {
      createComponent({
        props: {
          totalRepositorySize: withRootStorageStatistics.actualRepositorySizeLimit + 1,
          actualRepositorySizeLimit: withRootStorageStatistics.actualRepositorySizeLimit,
          totalRepositorySizeExcess: withRootStorageStatistics.totalRepositorySizeExcess,
          additionalPurchasedStorageSize: withRootStorageStatistics.additionalPurchasedStorageSize,
        },
      });
    });
  });

  describe('purchased storage card', () => {
    beforeEach(() => {
      createComponent();
    });

    it('passes the correct props when storageLimitEnforced is true', () => {
      createComponent({ props: { storageLimitEnforced: true } });
      expect(findPurchasedStorageCard().props()).toEqual({
        loading: false,
        showProgressBar: true,
        totalStorage: withRootStorageStatistics.additionalPurchasedStorageSize,
        usedStorage: withRootStorageStatistics.totalRepositorySizeExcess,
      });
    });
    it('passes the correct props when storageLimitEnforced is false', () => {
      createComponent({ props: { storageLimitEnforced: false } });
      expect(findPurchasedStorageCard().props()).toEqual({
        loading: false,
        showProgressBar: false,
        totalStorage: withRootStorageStatistics.additionalPurchasedStorageSize,
        usedStorage: withRootStorageStatistics.totalRepositorySizeExcess,
      });
    });

    it('renders card description with help link', () => {
      expect(findPurchasedStorageCard().text()).toContain('Purchased storage used');
      expect(findPurchasedStorageCard().findComponent(GlLink).exists()).toBe(true);
      expect(findPurchasedStorageCard().findComponent(GlLink).attributes('href')).toBe(
        projectHelpPaths.usageQuotasNamespaceStorageLimit,
      );
    });

    it('renders purchase more storage button', () => {
      const purchaseButton = findPurchasedStorageCard().findComponent(GlButton);

      expect(purchaseButton.exists()).toBe(true);
      expect(purchaseButton.attributes('href')).toBe('some-fancy-url');
    });

    describe('when purchaseStorageUrl is not passed', () => {
      beforeEach(() => {
        createComponent({
          provide: {
            purchaseStorageUrl: null,
          },
        });
      });

      it('does not render storage card if purchase storage url is not pased', () => {
        expect(findPurchasedStorageCard().exists()).toBe(false);
      });
    });

    describe('when there is no additional storage purchased', () => {
      it('renders card description with correct text', () => {
        createComponent({
          props: {
            totalRepositorySize: withRootStorageStatistics.totalRepositorySize,
            actualRepositorySizeLimit: withRootStorageStatistics.actualRepositorySizeLimit,
            totalRepositorySizeExcess: withRootStorageStatistics.totalRepositorySizeExcess,
            additionalPurchasedStorageSize: 0,
          },
        });

        expect(findPurchasedStorageCard().text()).toContain('Purchased storage');
      });
    });
  });
});
