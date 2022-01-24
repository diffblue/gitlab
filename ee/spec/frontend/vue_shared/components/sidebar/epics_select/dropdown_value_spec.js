import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import { nextTick } from 'vue';
import DropdownValue from 'ee/vue_shared/components/sidebar/epics_select/dropdown_value.vue';

import { mockEpic1 } from '../mock_data';

describe('EpicsSelect', () => {
  describe('DropdownValue', () => {
    let wrapper;

    beforeEach(() => {
      wrapper = shallowMount(DropdownValue, {
        propsData: {
          epic: mockEpic1,
        },
        slots: {
          default: 'None',
        },
      });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    describe('computed', () => {
      describe('hasEpic', () => {
        it('should return `true` when provided `epic` prop is a valid Epic object with title and url', () => {
          expect(wrapper.vm.hasEpic).toBe(true);
        });

        it('should return `false` when provided `epic` prop is an invalid Epic object', async () => {
          wrapper.setProps({
            epic: {},
          });

          await nextTick();
          expect(wrapper.vm.hasEpic).toBe(false);
        });
      });
    });

    describe('template', () => {
      it('should render component container', () => {
        expect(wrapper.classes()).toEqual(
          expect.arrayContaining(['value', 'js-epic-label', 'hide-collapsed']),
        );
      });

      it('should render epic title link element when `hasEpic` is true', () => {
        const titleEl = wrapper.findComponent(GlLink);

        expect(titleEl.exists()).toBe(true);
        expect(titleEl.attributes('href')).toBe(mockEpic1.url);
        expect(titleEl.text()).toBe(mockEpic1.title);
      });

      it('should render no value element with slot contents when `hasEpic` is false', async () => {
        wrapper.setProps({
          epic: {},
        });

        await nextTick();
        const noValueEl = wrapper.find('span.no-value');

        expect(noValueEl.exists()).toBe(true);
        expect(noValueEl.text()).toBe('None');
      });
    });
  });
});
