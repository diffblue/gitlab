import { GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import FilterItem from 'ee/security_dashboard/components/shared/filters/filter_item.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

describe('Filter Item component', () => {
  let wrapper;

  const defaultProps = {
    isChecked: false,
    text: 'filter',
  };

  const createWrapper = (props, slotContent = '') => {
    wrapper = shallowMount(FilterItem, {
      propsData: { ...defaultProps, ...props },
      slots: { default: slotContent },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const dropdownItem = () => wrapper.findComponent(GlDropdownItem);

  describe('text', () => {
    it('shows the given text when the "text" prop is passed in', () => {
      const text = 'some name';
      createWrapper({ text });
      expect(wrapper.text()).toContain(text);
    });

    it('shows slot content when slot content is passed in', () => {
      const slotContent = 'custom slot content';
      createWrapper({}, slotContent);
      expect(wrapper.text()).toContain(slotContent);
    });
  });

  describe('disabled state', () => {
    const tooltip = 'Not available';

    beforeEach(() => {
      createWrapper({ disabled: true, tooltip });
    });

    it('disables the dropdown item', () => {
      expect(dropdownItem().attributes('disabled')).toBeDefined();
    });

    it('displays tooltip', () => {
      const tooltipItem = getBinding(dropdownItem().element, 'gl-tooltip');

      expect(tooltipItem.value).toBe(tooltip);
      expect(tooltipItem.modifiers).toEqual({
        d0: true,
        left: true,
        viewport: true,
      });
    });
  });

  it.each([true, false])('shows the expected checkmark when isSelected is %s', (isChecked) => {
    createWrapper({ isChecked });
    expect(dropdownItem().props('isChecked')).toBe(isChecked);
  });

  it('emits click event when clicked', () => {
    createWrapper();
    dropdownItem().element.click();

    expect(wrapper.emitted('click')).toHaveLength(1);
  });
});
