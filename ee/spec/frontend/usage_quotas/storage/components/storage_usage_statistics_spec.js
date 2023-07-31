import { GlButton, GlLink, GlSprintf, GlProgressBar } from '@gitlab/ui';
import StorageStatisticsCard from 'ee/usage_quotas/storage/components/storage_statistics_card.vue';
import numberToHumanSize from 'ee/usage_quotas/storage/components/number_to_human_size.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  NAMESPACE_STORAGE_OVERVIEW_SUBTITLE,
  NAMESPACE_ENFORCEMENT_TYPE,
} from 'ee/usage_quotas/storage/constants';
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
        numberToHumanSize,
        GlSprintf,
        GlButton,
        GlLink,
        GlProgressBar,
      },
    });
  };

  const findNamespaceStorageCard = () => wrapper.findComponent(StorageStatisticsCard);
  const findStorageDetailCard = () => wrapper.findByTestId('storage-detail-card');
  const findStorageIncludedInPlan = () => wrapper.findByTestId('storage-included-in-plan');
  const findStoragePurchased = () => wrapper.findByTestId('storage-purchased');
  const findTotalStorage = () => wrapper.findByTestId('total-storage');
  const findOverviewSubtitle = () => wrapper.findByTestId('overview-subtitle');

  describe('namespace overview section', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows the namespace storage overview subtitle', () => {
      expect(findOverviewSubtitle().text()).toBe(NAMESPACE_STORAGE_OVERVIEW_SUBTITLE);
    });

    describe('purchase more storage button', () => {
      it('renders the button if purchaseStorageUrl is provided', () => {
        expect(wrapper.findComponent(GlButton).exists()).toBe(true);
      });

      it('does not render the button if purchaseStorageUrl is not provided', () => {
        createComponent({
          provide: {
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
            enforcementType: NAMESPACE_ENFORCEMENT_TYPE,
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
        totalStorage:
          withRootStorageStatistics.actualRepositorySizeLimit +
          withRootStorageStatistics.additionalPurchasedStorageSize,
        loading: false,
      });
    });
  });

  describe('storage available card', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('storage included in the plan', () => {
      it('renders storage included in the plan', () => {
        expect(findStorageIncludedInPlan().text()).toContain('978.8 KiB');
      });

      it('renders per project copy if enforcementType is project', () => {
        expect(wrapper.text()).toContain('Storage per project included in Free subscription');
      });

      it('renders namespace enforcement copy if enforcementType is namespace', () => {
        createComponent({
          provide: {
            enforcementType: NAMESPACE_ENFORCEMENT_TYPE,
          },
        });

        expect(wrapper.text()).toContain('Included in Free subscription');
      });
    });

    it('renders purchased storage', () => {
      expect(findStoragePurchased().text()).toContain('321 B');
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
