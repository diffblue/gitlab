import { GlLink, GlSprintf, GlProgressBar } from '@gitlab/ui';
import StorageStatisticsCard from 'ee/usage_quotas/storage/components/storage_statistics_card.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { NAMESPACE_STORAGE_OVERVIEW_SUBTITLE } from 'ee/usage_quotas/storage/constants';
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
        namespacePlanName: 'Free',
        namespacePlanStorageIncluded: withRootStorageStatistics.actualRepositorySizeLimit,
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
  const findStorageDetailCard = () => wrapper.findByTestId('storage-detail-card');
  const findStorageIncludedInPlan = () => wrapper.findByTestId('storage-included-in-plan');
  const findStoragePurchased = () => wrapper.findByTestId('storage-purchased');
  const findTotalStorage = () => wrapper.findByTestId('total-storage');
  const findOverviewSubtitle = () => wrapper.findByTestId('overview-subtitle');

  describe('namespace storage card', () => {
    it('shows the namespace storage overview subtitle', () => {
      createComponent();

      expect(findOverviewSubtitle().text()).toBe(NAMESPACE_STORAGE_OVERVIEW_SUBTITLE);
    });

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

  describe('storage detail card', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders storage included in the plan', () => {
      expect(findStorageIncludedInPlan().text()).toContain('978.8 KiB');
    });

    it('renders purchased storage', () => {
      expect(findStoragePurchased().text()).toContain('0.3 KiB');
    });

    it('renders total storage', () => {
      expect(findTotalStorage().text()).toContain('979.1 KiB');
    });

    describe('when GitLab instance has no Plan attatched to namespace', () => {
      beforeEach(() => {
        createComponent({
          provide: {
            namespacePlanName: null,
          },
        });
      });

      it('does not render storage card if there is no plan information', () => {
        expect(findStorageDetailCard().exists()).toBe(false);
      });
    });
  });
});
