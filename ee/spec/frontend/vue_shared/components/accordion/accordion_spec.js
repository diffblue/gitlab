import { shallowMount } from '@vue/test-utils';
import { Accordion } from 'ee/vue_shared/components/accordion';

jest.mock('lodash/uniqueId', () => () => 'foo');

describe('Accordion component', () => {
  let wrapper;
  const factory = ({ defaultSlot = '', propsData = {} } = {}) => {
    wrapper = shallowMount(Accordion, {
      propsData,
      scopedSlots: {
        default: defaultSlot,
      },
    });
  };

  it('contains a default slot', () => {
    const defaultSlot = `<span class="content"></span>`;

    factory({ defaultSlot });

    expect(wrapper.find('.content').exists()).toBe(true);
  });

  it('passes a unique "accordionId" to the default slot', () => {
    const mockUniqueIdValue = 'foo';

    const defaultSlot = '<span>{{ props.accordionId }}</span>';

    factory({ defaultSlot });

    expect(wrapper.text()).toContain(mockUniqueIdValue);
  });

  it('accepts a list of CSS classes to be applied to the list element within the component', () => {
    const listClasses = ['foo', 'bar'];

    factory({
      propsData: {
        listClasses,
      },
    });

    expect(wrapper.find('ul').classes()).toEqual(expect.arrayContaining(listClasses));
  });
});
