import { GlToggle } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import VueRouter from 'vue-router';
import Filters from 'ee/security_dashboard/components/pipeline/filters.vue';
import { setupStore } from 'ee/security_dashboard/store';
import state from 'ee/security_dashboard/store/modules/filters/state';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

Vue.use(Vuex);
Vue.use(VueRouter);

describe('Filter component', () => {
  let wrapper;
  let store;

  const createWrapper = ({ mountFn = shallowMount } = {}) => {
    wrapper = extendedWrapper(
      mountFn(Filters, {
        store,
        router: new VueRouter(),
        provide: { dashboardType: 'pipeline' },
        slots: {
          buttons: '<div class="button-slot"></div>',
        },
      }),
    );
  };

  beforeEach(() => {
    store = new Vuex.Store();
    setupStore(store);
  });

  describe('severity', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should display all filters', () => {
      expect(wrapper.findAll('.js-filter')).toHaveLength(2);
    });

    it('should display "Hide dismissed vulnerabilities" toggle', () => {
      expect(wrapper.findComponent(GlToggle).props('label')).toBe(Filters.i18n.toggleLabel);
    });
  });

  describe('buttons slot', () => {
    it('should exist', () => {
      createWrapper();
      expect(wrapper.find('.button-slot').exists()).toBe(true);
    });
  });

  describe('tool filter', () => {
    it('should call the setFilter action with the correct data when the scanner filter is changed', async () => {
      const mock = jest.fn();
      store = new Vuex.Store({
        modules: {
          filters: {
            namespaced: true,
            state,
            actions: { setFilter: mock },
          },
        },
      });

      createWrapper({ mountFn: mount });
      await nextTick();
      // The other filters will trigger the mock as well, so we'll clear it before clicking on a
      // scanner filter item.
      mock.mockClear();

      const filterId = 'severity';
      const optionId = 'MEDIUM';
      const option = wrapper.findByTestId(optionId);
      option.vm.$emit('click');
      await nextTick();

      expect(mock).toHaveBeenCalledTimes(1);
      expect(mock).toHaveBeenCalledWith(expect.any(Object), { [filterId]: [optionId] });
    });
  });
});
