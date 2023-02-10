import { GlModal } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AddRuleModal from 'ee/protected_environments/add_rule_modal.vue';

describe('ee/protected_environments/add_rule_modal.vue', () => {
  let wrapper;

  const createComponent = ({ visible = true, title = 'Test Title', slot = '' } = {}) =>
    shallowMountExtended(AddRuleModal, {
      propsData: {
        visible,
      },
      attrs: {
        title,
      },
      slots: {
        'add-rule-form': slot,
      },
      stubs: { GlModal },
    });

  const findModal = () => wrapper.findComponent(GlModal);

  it('forwards attributes to gl-modal', () => {
    const title = 'different title';
    wrapper = createComponent({ title });

    expect(findModal().props('title')).toBe(title);
  });

  it('displays the slot', () => {
    const slot = '<div data-testid="slot">hello</div>';
    wrapper = createComponent({ slot });

    expect(wrapper.findByTestId('slot').exists()).toBe(true);
  });

  it('binds visible', () => {
    const visible = false;
    wrapper = createComponent({ visible });

    expect(findModal().props('visible')).toBe(false);
  });

  it('binds the modal change event to change', () => {
    const visible = false;
    wrapper = createComponent();

    findModal().vm.$emit('change', visible);

    expect(wrapper.emitted('change')).toEqual([[visible]]);
  });

  it('binds the modal primary event to saveRule', () => {
    wrapper = createComponent();

    findModal().vm.$emit('primary');

    expect(wrapper.emitted('saveRule')).toEqual([[]]);
  });
});
