import { GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import ToggleEpicsSwimlanes from 'ee/boards/components/toggle_epics_swimlanes.vue';

describe('ToggleEpicsSwimlanes', () => {
  let wrapper;

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findToggleItems = () => wrapper.findAllComponents(GlListboxItem);

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

  it('emits toggleSwimlanes event on select group by epic', async () => {
    createComponent();
    await nextTick();

    expect(findToggleItems()).toHaveLength(2);

    expect(findToggleItems().at(1).props('isSelected')).toBe(false);

    findListbox().vm.$emit('select');

    expect(wrapper.emitted('toggleSwimlanes')).toHaveLength(1);
  });
});
