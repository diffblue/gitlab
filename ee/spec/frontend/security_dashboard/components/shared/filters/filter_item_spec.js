import { GlDropdownItem, GlTruncate } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import FilterItem from 'ee/security_dashboard/components/shared/filters/filter_item.vue';

describe('Filter Item component', () => {
  let wrapper;
  let glTooltipDirectiveMock;

  const defaultProps = {
    isChecked: false,
    text: 'filter',
  };

  const createWrapper = (props, slotContent = '') => {
    glTooltipDirectiveMock = jest.fn();
    wrapper = shallowMount(FilterItem, {
      directives: {
        GlTooltip: glTooltipDirectiveMock,
      },
      propsData: { ...defaultProps, ...props },
      slots: { default: slotContent },
    });
  };

  const dropdownItem = () => wrapper.findComponent(GlDropdownItem);
  const findTruncate = () => wrapper.findComponent(GlTruncate);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('text', () => {
    it('shows the given text when the "text" prop is passed in', () => {
      const text = 'some name';
      createWrapper({ text });
      expect(wrapper.text()).toContain(text);
      expect(glTooltipDirectiveMock.mock.calls[0][1].value.disabled).toBe(true);
    });

    it('disables the tooltip when the "truncate" prop is not passed in', () => {
      createWrapper({});
      expect(glTooltipDirectiveMock.mock.calls[0][1].value.disabled).toBe(true);
    });

    it('shows slot content when slot content is passed in', () => {
      const slotContent = 'custom slot content';
      createWrapper({}, slotContent);
      expect(wrapper.text()).toContain(slotContent);
    });

    it('shows the given text as truncated when the "truncate" prop is passed in', () => {
      createWrapper({ truncate: true });
      expect(findTruncate().exists()).toBe(true);
    });

    it('shows the tooltip when the "truncate" prop is passed in', () => {
      createWrapper({ truncate: true });
      expect(glTooltipDirectiveMock.mock.calls[0][1].value.disabled).toBe(false);
      expect(glTooltipDirectiveMock.mock.calls[0][1].value.title).toBe(defaultProps.text);
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
