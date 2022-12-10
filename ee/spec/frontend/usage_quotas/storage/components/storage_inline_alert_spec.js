import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import StorageInlineAlert from 'ee/usage_quotas/storage/components/storage_inline_alert.vue';

const GB_IN_BYTES = 1_074_000_000;
const THIRTEEN_GB_IN_BYTES = 13 * GB_IN_BYTES;
const TEN_GB_IN_BYTES = 10 * GB_IN_BYTES;
const FIVE_GB_IN_BYTES = 5 * GB_IN_BYTES;
const THREE_GB_IN_BYTES = 3 * GB_IN_BYTES;

describe('StorageInlineAlert', () => {
  let wrapper;

  function mountComponent(props) {
    wrapper = shallowMount(StorageInlineAlert, {
      propsData: props,
    });
  }

  const findAlert = () => wrapper.findComponent(GlAlert);

  describe('no excess storage and no purchase', () => {
    beforeEach(() => {
      mountComponent({
        containsLockedProjects: false,
        repositorySizeExcessProjectCount: 0,
        totalRepositorySizeExcess: 0,
        totalRepositorySize: FIVE_GB_IN_BYTES,
        additionalPurchasedStorageSize: 0,
        actualRepositorySizeLimit: TEN_GB_IN_BYTES,
      });
    });

    it('does not render an alert', () => {
      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('excess storage and no purchase', () => {
    beforeEach(() => {
      mountComponent({
        containsLockedProjects: true,
        repositorySizeExcessProjectCount: 1,
        totalRepositorySizeExcess: THREE_GB_IN_BYTES,
        totalRepositorySize: THIRTEEN_GB_IN_BYTES,
        additionalPurchasedStorageSize: 0,
        actualRepositorySizeLimit: TEN_GB_IN_BYTES,
      });
    });

    it('renders danger alert with correct message', () => {
      const alert = findAlert();
      expect(alert.props('variant')).toBe('danger');
      expect(alert.text()).toBe(
        'You have reached the free storage limit on 1 project. To unlock them, purchase additional storage.',
      );
    });
  });

  describe('excess storage below purchase limit', () => {
    beforeEach(() => {
      mountComponent({
        containsLockedProjects: false,
        repositorySizeExcessProjectCount: 0,
        totalRepositorySizeExcess: THREE_GB_IN_BYTES,
        totalRepositorySize: THIRTEEN_GB_IN_BYTES,
        additionalPurchasedStorageSize: FIVE_GB_IN_BYTES,
        actualRepositorySizeLimit: TEN_GB_IN_BYTES,
      });
    });

    it('renders info alert with correct message', () => {
      const alert = findAlert();
      expect(alert.props('variant')).toBe('info');
      expect(alert.text()).toBe(
        'When you purchase additional storage, we automatically unlock projects that were locked if the storage limit was reached.',
      );
    });
  });

  describe('excess storage above purchase limit', () => {
    beforeEach(() => {
      mountComponent({
        containsLockedProjects: true,
        repositorySizeExcessProjectCount: 1,
        totalRepositorySizeExcess: THREE_GB_IN_BYTES,
        totalRepositorySize: THIRTEEN_GB_IN_BYTES,
        additionalPurchasedStorageSize: THREE_GB_IN_BYTES,
        actualRepositorySizeLimit: TEN_GB_IN_BYTES,
      });
    });

    it('renders danger alert with correct message', () => {
      const alert = findAlert();
      expect(alert.props('variant')).toBe('danger');
      expect(alert.text()).toBe(
        'You have consumed all of your additional storage. Purchase more to unlock projects over the limit.',
      );
    });
  });
});
