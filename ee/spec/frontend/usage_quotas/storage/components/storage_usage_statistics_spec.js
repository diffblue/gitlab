import { GlButton, GlLink, GlSprintf, GlProgressBar } from '@gitlab/ui';
import StorageStatisticsCard from 'ee/usage_quotas/storage/components/storage_statistics_card.vue';
import TotalStorageAvailableBreakdownCard from 'ee/usage_quotas/storage/components/total_storage_available_breakdown_card.vue';
import ExcessStorageBreakdownCard from 'ee/usage_quotas/storage/components/excess_storage_breakdown_card.vue';
import NumberToHumanSize from 'ee/usage_quotas/storage/components/number_to_human_size.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { NAMESPACE_STORAGE_OVERVIEW_SUBTITLE } from 'ee/usage_quotas/storage/constants';
import StorageUsageStatistics from 'ee/usage_quotas/storage/components/storage_usage_statistics.vue';

import { withRootStorageStatistics, defaultNamespaceProvideValues } from '../mock_data';

describe('StorageUsageStatistics', () => {
  let wrapper;

  const createComponent = ({ props = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(StorageUsageStatistics, {
      propsData: {
        additionalPurchasedStorageSize: withRootStorageStatistics.additionalPurchasedStorageSize,
        usedStorage: withRootStorageStatistics.rootStorageStatistics.storageSize,
        loading: false,
        ...props,
      },
      provide: {
        ...defaultNamespaceProvideValues,
        ...provide,
      },
      stubs: {
        StorageStatisticsCard,
        NumberToHumanSize,
        GlSprintf,
        GlButton,
        GlLink,
        GlProgressBar,
      },
    });
  };

  const findNamespaceStorageCard = () => wrapper.findComponent(StorageStatisticsCard);
  const findTotalStorageAvailableBreakdownCard = () =>
    wrapper.findComponent(TotalStorageAvailableBreakdownCard);
  const findExcessStorageBreakdownCard = () => wrapper.findComponent(ExcessStorageBreakdownCard);
  const findOverviewSubtitle = () => wrapper.findByTestId('overview-subtitle');

  describe('namespace overview section', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows the namespace storage overview subtitle', () => {
      expect(findOverviewSubtitle().text()).toBe(NAMESPACE_STORAGE_OVERVIEW_SUBTITLE);
    });

    describe('purchase more storage button when namespace is using project enforcement', () => {
      it('does not render the button', () => {
        createComponent();
        expect(wrapper.findComponent(GlButton).exists()).toBe(false);
      });
    });

    describe('purchase more storage button when namespace is NOT using project enforcement', () => {
      it('renders the button if purchaseStorageUrl is provided', () => {
        createComponent({
          provide: {
            isUsingProjectEnforcement: false,
          },
        });
        expect(wrapper.findComponent(GlButton).exists()).toBe(true);
      });

      it('does not render the button if purchaseStorageUrl is not provided', () => {
        createComponent({
          provide: {
            isUsingProjectEnforcement: false,
            purchaseStorageUrl: undefined,
          },
        });

        expect(wrapper.findComponent(GlButton).exists()).toBe(false);
      });
    });

    describe('enforcement type subtitle', () => {
      it('renders project enforcement copy if enforcementType is project', () => {
        expect(wrapper.text()).toContain(
          'Projects under this namespace have 978.8 KiB of storage. How are limits applied?',
        );
      });

      it('renders namespace enforcement copy if enforcementType is namespace', () => {
        // Namespace enforcement type is declared in ee/app/models/namespaces/storage/root_size.rb
        // More about namespace storage limit at https://docs.gitlab.com/ee/user/usage_quotas#namespace-storage-limit
        createComponent({
          provide: {
            isUsingProjectEnforcement: false,
          },
        });

        expect(wrapper.text()).toContain(
          'This namespace has 978.8 KiB of storage. How are limits applied?',
        );
      });
    });
  });

  describe('StorageStatisticsCard', () => {
    it('passes the correct props to StorageStatisticsCard', () => {
      createComponent();

      expect(findNamespaceStorageCard().props()).toEqual({
        usedStorage: withRootStorageStatistics.rootStorageStatistics.storageSize,
        planStorageDescription: 'Storage per project included in Free subscription',
        totalStorage:
          withRootStorageStatistics.actualRepositorySizeLimit +
          withRootStorageStatistics.additionalPurchasedStorageSize,
        loading: false,
      });
    });
  });

  describe('TotalStorageAvailableBreakdownCard', () => {
    it('does not render TotalStorageAvailableBreakdownCard when namespace is using project enforcement', () => {
      createComponent();
      expect(findTotalStorageAvailableBreakdownCard().exists()).toBe(false);
    });

    it('passes the correct props to TotalStorageAvailableBreakdownCard when namespace is NOT using project enforcement', () => {
      createComponent({
        provide: {
          isUsingProjectEnforcement: false,
        },
      });

      expect(findTotalStorageAvailableBreakdownCard().props()).toEqual({
        planStorageDescription: 'Included in Free subscription',
        includedStorage: withRootStorageStatistics.actualRepositorySizeLimit,
        purchasedStorage: withRootStorageStatistics.additionalPurchasedStorageSize,
        totalStorage:
          withRootStorageStatistics.actualRepositorySizeLimit +
          withRootStorageStatistics.additionalPurchasedStorageSize,
        loading: false,
      });
    });

    it('does not render storage card if there is no plan information', () => {
      createComponent({
        provide: {
          namespacePlanName: null,
        },
      });

      expect(findTotalStorageAvailableBreakdownCard().exists()).toBe(false);
    });
  });

  describe('ExcessStorageBreakdownCard', () => {
    it('does not render ExcessStorageBreakdownCard when namespace is NOT using project enforcement', () => {
      createComponent({
        provide: {
          isUsingProjectEnforcement: false,
        },
      });
      expect(findExcessStorageBreakdownCard().exists()).toBe(false);
    });

    it('passes the correct props to ExcessStorageBreakdownCard when namespace is using project enforcement', () => {
      createComponent();

      expect(findExcessStorageBreakdownCard().props()).toEqual({
        purchasedStorage: withRootStorageStatistics.additionalPurchasedStorageSize,
        loading: false,
      });
    });

    it('does not render storage card if there is no plan information', () => {
      createComponent({
        provide: {
          namespacePlanName: null,
        },
      });

      expect(findExcessStorageBreakdownCard().exists()).toBe(false);
    });
  });
});
