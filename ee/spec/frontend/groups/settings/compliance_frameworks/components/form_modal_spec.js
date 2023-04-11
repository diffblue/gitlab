import { shallowMount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';

import FormModal from 'ee/groups/settings/compliance_frameworks/components/form_modal.vue';
import CreateForm from 'ee/groups/settings/compliance_frameworks/components/create_form.vue';

jest.mock('~/lib/utils/url_utility');

describe('FormModal', () => {
  let wrapper;

  const findModal = () => wrapper.findComponent(GlModal);
  const findCreateForm = () => wrapper.findComponent(CreateForm);

  function createComponent(props = {}, mountFn = shallowMount) {
    return mountFn(FormModal, {
      propsData: {
        ...props,
      },
    });
  }

  describe('initialized', () => {
    it('sets the modal title when adding', () => {
      wrapper = createComponent();

      expect(findModal().props('title')).toBe('New compliance framework');
    });

    it('emits the change event on success', async () => {
      wrapper = createComponent();

      expect(wrapper.emitted('change')).toBe(undefined);

      await findCreateForm().vm.$emit('success');

      expect(wrapper.emitted('change')).toHaveLength(1);
    });
  });
});
