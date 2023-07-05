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
        actualRepositorySizeLimit: withRootStorageStatistics.actualRepositorySizeLimit,
        additionalPurchasedStorageSize: withRootStorageStatistics.additionalPurchasedStorageSize,
        loading: false,
        ...props,
      },
      provide: {
        purchaseStorageUrl: 'some-fancy-url',
        buyAddonTargetAttr: '_self',
        namespacePlanName: 'Free',
        enforcementType: 'project_repository_limit',
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

    describe('additional storage purchased', () => {
      createComponent({
        props: {
          usedStorage: withRootStorageStatistics.actualRepositorySizeLimit + 1,
          actualRepositorySizeLimit: withRootStorageStatistics.actualRepositorySizeLimit,
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
