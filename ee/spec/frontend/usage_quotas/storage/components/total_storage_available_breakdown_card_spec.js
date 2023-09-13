import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TotalStorageAvailableBreakdownCard from 'ee/usage_quotas/storage/components/total_storage_available_breakdown_card.vue';
import NumberToHumanSize from 'ee/usage_quotas/storage/components/number_to_human_size.vue';

import { withRootStorageStatistics, defaultNamespaceProvideValues } from '../mock_data';

describe('TotalStorageAvailableBreakdownCard', () => {
  let wrapper;

  const createComponent = ({ props = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(TotalStorageAvailableBreakdownCard, {
      propsData: {
        includedStorage: withRootStorageStatistics.actualRepositorySizeLimit,
        purchasedStorage: withRootStorageStatistics.additionalPurchasedStorageSize,
        totalStorage:
          withRootStorageStatistics.actualRepositorySizeLimit +
          withRootStorageStatistics.additionalPurchasedStorageSize,
        loading: false,
        planStorageDescription: 'Included in Free subscription',
        ...props,
      },
      provide: {
        ...defaultNamespaceProvideValues,
        isUsingProjectEnforcement: false,
        ...provide,
      },
      stubs: {
        NumberToHumanSize,
      },
    });
  };

  const findStorageIncludedInPlan = () => wrapper.findByTestId('storage-included-in-plan');
  const findStoragePurchased = () => wrapper.findByTestId('storage-purchased');
  const findTotalStorage = () => wrapper.findByTestId('total-storage');

  beforeEach(() => {
    createComponent();
  });

  it('renders storage included in the plan', () => {
    expect(findStorageIncludedInPlan().text()).toContain('978.8 KiB');
  });

  it('renders plan storage description', () => {
    expect(wrapper.text()).toContain('Included in Free subscription');
  });

  it('renders purchased storage', () => {
    expect(findStoragePurchased().text()).toContain('321 B');
  });

  it('renders total storage', () => {
    expect(findTotalStorage().text()).toContain('979.1 KiB');
  });
});
