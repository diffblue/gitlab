import { mount } from '@vue/test-utils';
import DropdownButtonText from 'ee/security_dashboard/components/shared/filters/dropdown_button_text.vue';

describe('Dropdown Button Text component', () => {
  let wrapper;

  const createWrapper = (items) => {
    wrapper = mount(DropdownButtonText, {
      propsData: { items },
    });
  };

  it.each`
    items                             | expected
    ${[]}                             | ${''}
    ${['Item 1']}                     | ${'Item 1'}
    ${['Item 1', 'Item 2']}           | ${'Item 1 +1 more'}
    ${['Item 1', 'Item 2', 'Item 3']} | ${'Item 1 +2 more'}
  `('shows "$expected" when the items are $items', ({ items, expected }) => {
    createWrapper(items);

    expect(wrapper.text()).toMatchInterpolatedText(expected);
  });
});
