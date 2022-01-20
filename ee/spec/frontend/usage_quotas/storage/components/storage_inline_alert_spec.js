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

    it('renders danger variant alert', () => {
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().props('variant')).toBe('danger');
    });

    it('renders human readable repositoryFreeLimit', () => {
      expect(findAlert().text()).toBe(
        'You have reached the free storage limit of 10.0GiB on 1 project. To unlock them, please purchase additional storage.',
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

    it('renders info variant alert', () => {
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().props('variant')).toBe('info');
    });

    it('renders text explaining storage', () => {
      expect(findAlert().text()).toBe(
        'When you purchase additional storage, we automatically unlock projects that were locked when you reached the 10.0GiB limit.',
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

    it('renders danger alert', () => {
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().props('variant')).toBe('danger');
    });
  });
});
