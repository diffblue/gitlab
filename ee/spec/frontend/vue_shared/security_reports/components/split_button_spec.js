import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SplitButton from 'ee/vue_shared/security_reports/components/split_button.vue';
import * as urlUtility from '~/lib/utils/url_utility';

const buttons = [
  {
    name: 'button one',
    tagline: "button one's tagline",
    isLoading: false,
    action: 'button1Action',
  },
  {
    name: 'button two',
    tagline: "button two's tagline",
    isLoading: false,
    action: 'button2Action',
  },
];

describe('Split Button', () => {
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);

  const createComponent = (props) => {
    wrapper = shallowMount(SplitButton, {
      propsData: {
        ...props,
      },
    });
  };

  it('does not render dropdown if buttons array is empty', () => {
    createComponent({
      buttons: [],
    });

    expect(findDropdown().exists()).toBe(false);
  });

  it('renders disabled dropdown if disabled prop is true', () => {
    createComponent({
      buttons: buttons.slice(0),
      disabled: true,
    });

    expect(findDropdown().attributes().disabled).toBe('true');
  });

  it('renders a loading icon when loading prop is true', () => {
    createComponent({ buttons: buttons.slice(0).map((b) => ({ ...b, loading: true })) });
    expect(findDropdown().attributes().loading).toBe('true');
  });

  it('emits correct action on dropdown click', () => {
    createComponent({
      buttons: buttons.slice(0),
    });

    findDropdown().vm.$emit('click');

    expect(wrapper.emitted('button1Action')).toBeDefined();
    expect(wrapper.emitted('button1Action')).toHaveLength(1);
  });

  it('visits url if href property is specified', () => {
    const spy = jest.spyOn(urlUtility, 'visitUrl').mockReturnValue({});
    const href = 'https://gitlab.com';

    createComponent({
      buttons: [{ ...buttons.slice(0), action: undefined, href }],
    });

    findDropdown().vm.$emit('click');

    expect(wrapper.emitted('button1Action')).toBeUndefined();
    expect(spy).toHaveBeenCalledWith(href, true);
  });

  it('renders a correct amount of dropdown items', () => {
    createComponent({
      buttons,
    });

    expect(findDropdownItems()).toHaveLength(2);
  });

  it('renders an icon if dropdown item is selected', () => {
    createComponent({
      buttons: buttons.slice(0),
    });

    expect(findDropdownItems().at(0).props('isChecked')).toBe(true);
  });
});
