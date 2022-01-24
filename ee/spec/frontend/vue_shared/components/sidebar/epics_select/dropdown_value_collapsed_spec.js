import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import DropdownValueCollapsed from 'ee/vue_shared/components/sidebar/epics_select/dropdown_value_collapsed.vue';

import { mockEpic1 } from '../mock_data';

describe('EpicsSelect', () => {
  describe('DropdownValueCollapsed', () => {
    let wrapper;

    beforeEach(() => {
      wrapper = shallowMount(DropdownValueCollapsed, {
        directives: {
          GlTooltip: {},
        },
        propsData: {
          epic: mockEpic1,
        },
      });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    describe('template', () => {
      it('should render component container', () => {
        expect(wrapper.classes()).toContain('sidebar-collapsed-icon');
        expect(wrapper.attributes('title')).toBe(mockEpic1.title);
      });

      it('should render Icon component', () => {
        const iconEl = wrapper.findComponent(GlIcon);

        expect(iconEl.exists()).toBe(true);
        expect(iconEl.attributes('name')).toBe('epic');
      });

      it('should render epic title element', () => {
        const titleEl = wrapper.find('.collapse-truncated-title');

        expect(titleEl.exists()).toBe(true);
        expect(titleEl.text()).toBe(mockEpic1.title);
      });
    });
  });
});
