import { GlModal } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import TemporaryStorageIncreaseModal from 'ee/usage_quotas/storage/components/temporary_storage_increase_modal.vue';

const TEST_LIMIT = '8 bytes';
const TEST_MODAL_ID = 'test-modal-id';

describe('Temporary storage increase modal', () => {
  let wrapper;

  const createComponent = (mountFn, props = {}) => {
    wrapper = mountFn(TemporaryStorageIncreaseModal, {
      propsData: {
        modalId: TEST_MODAL_ID,
        limit: TEST_LIMIT,
        ...props,
      },
    });
  };
  const findModal = () => wrapper.findComponent(GlModal);
  const showModal = () => {
    findModal().vm.show();
    return wrapper.vm.$nextTick();
  };
  const findModalText = () => document.body.innerText;

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('shows modal message', async () => {
    createComponent(mount);

    await showModal();

    const text = findModalText();
    expect(text).toContain('GitLab allows you a free, one-time storage increase.');
    expect(text).toContain(`your original storage limit of ${TEST_LIMIT} applies.`);
  });

  it('passes along modalId', () => {
    createComponent(shallowMount);

    expect(findModal().attributes('modalid')).toBe(TEST_MODAL_ID);
  });
});
