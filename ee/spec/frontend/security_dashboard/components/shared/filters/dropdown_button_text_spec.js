import { mount } from '@vue/test-utils';
import { GlTruncate } from '@gitlab/ui';
import DropdownButtonText from 'ee/security_dashboard/components/shared/filters/dropdown_button_text.vue';

describe('Dropdown Button Text component', () => {
  let wrapper;

  const createWrapper = ({ items = [], name = 'filterName' }) => {
    wrapper = mount(DropdownButtonText, {
      propsData: { items, name },
    });
  };

  const findTruncate = () => wrapper.findComponent(GlTruncate);

  it.each`
    items                             | expected
    ${[]}                             | ${''}
    ${['Item 1']}                     | ${'Item 1'}
    ${['Item 1', 'Item 2']}           | ${'Item 1 +1 more'}
    ${['Item 1', 'Item 2', 'Item 3']} | ${'Item 1 +2 more'}
  `('shows "$expected" when the items are $items', ({ items, expected }) => {
    createWrapper({ items });

    expect(wrapper.text()).toMatchInterpolatedText(expected);
  });

  it.each`
    name             | expectedSelector
    ${'status'}      | ${'filter_status_dropdown'}
    ${'Tool'}        | ${'filter_tool_dropdown'}
    ${'Report Type'} | ${'filter_report_type_dropdown'}
  `('has expected QA selector - $expectedSelector', ({ name, expectedSelector }) => {
    createWrapper({ name });

    expect(findTruncate().attributes('data-qa-selector')).toBe(expectedSelector);
  });
});
