import { GlButton, GlTooltip } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ActionButton from 'ee/on_demand_scans/components/action_button.vue';

describe('ActionButton', () => {
  let wrapper;

  // Props
  const actionType = 'action';
  const label = 'Action label';

  // Finders
  const findButton = () => wrapper.findComponent(GlButton);
  const findTooltip = () => wrapper.findComponent(GlTooltip);

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(ActionButton, {
      propsData: {
        actionType,
        label,
        ...props,
      },
    });
  };

  it('renders a button with a tooltip attached', () => {
    createComponent();
    const button = findButton();
    const tooltip = findTooltip();

    expect(button.exists()).toBe(true);
    expect(tooltip.exists()).toBe(true);
    expect(tooltip.props('target')).toBe(button.attributes('id'));
  });

  it('sets the label on the button and in the tooltip', () => {
    createComponent();

    expect(findButton().attributes('aria-label')).toBe(label);
    expect(findTooltip().text()).toBe(label);
  });

  it('emits bv::hide::tooltip and click events on click', () => {
    createComponent();
    jest.spyOn(wrapper.vm.$root, '$emit');
    findButton().vm.$emit('click');

    expect(wrapper.vm.$root.$emit).toHaveBeenCalledWith('bv::hide::tooltip', expect.any(String));
    expect(wrapper.emitted('click')).toHaveLength(1);
  });

  it('does not set the loading state by default', () => {
    createComponent();

    expect(findButton().props('loading')).toBe(false);
  });

  it('passes the loading state down to the button', () => {
    createComponent({ isLoading: true });

    expect(findButton().props('loading')).toBe(true);
  });

  it('passes attributes down to the button', () => {
    const href = '/edit/path';
    createComponent({
      href,
    });

    expect(findButton().attributes('href')).toBe(href);
  });
});
