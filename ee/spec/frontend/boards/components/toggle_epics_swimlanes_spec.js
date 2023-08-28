import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { __ } from '~/locale';

import ToggleEpicsSwimlanes from 'ee/boards/components/toggle_epics_swimlanes.vue';

describe('ToggleEpicsSwimlanes', () => {
  let wrapper;

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findLabel = () => wrapper.findByTestId('toggle-swimlanes-label');

  const createComponent = ({ isSwimlanesOn = false } = {}) => {
    wrapper = shallowMountExtended(ToggleEpicsSwimlanes, {
      propsData: {
        isSwimlanesOn,
      },
      provide: {
        isApolloBoard: true,
      },
      stubs: {
        GlCollapsibleListbox,
      },
    });
  };

  it('emits toggleSwimlanes event on select', () => {
    createComponent();

    findListbox().vm.$emit('select', 'epic');

    expect(wrapper.emitted('toggleSwimlanes')).toHaveLength(1);
  });

  it('renders a label', () => {
    createComponent();

    expect(findLabel().attributes()).toMatchObject({
      for: 'swimlane-listbox',
    });
  });

  it('passes the correct props to listbox', () => {
    createComponent();

    expect(findListbox().props('items')).toHaveLength(2);
    expect(findListbox().props('selected')).toEqual('no_grouping');
    expect(findListbox().props('toggleText')).toEqual(__('None'));
    expect(findListbox().attributes()).toMatchObject({
      id: 'swimlane-listbox',
    });
  });

  it('maintains state when props are changed', () => {
    createComponent({ isSwimlanesOn: true });
    expect(findListbox().props('toggleText')).toBe('Epic');
    wrapper.setProps({ isSwimlanesOn: false });

    expect(findListbox().props('toggleText')).toBe('Epic');
    expect(wrapper.emitted('toggleSwimlanes')).toBeUndefined();
  });
});
