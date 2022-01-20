import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import ToggleEpicsSwimlanes from 'ee/boards/components/toggle_epics_swimlanes.vue';

Vue.use(Vuex);

describe('ToggleEpicsSwimlanes', () => {
  let store;
  let wrapper;

  const createComponent = () => {
    wrapper = mount(ToggleEpicsSwimlanes, { store });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  beforeEach(() => {
    store = new Vuex.Store({ state: { isShowingEpicsSwimlanes: false } });
    createComponent();
  });

  describe('dropdownLabel', () => {
    it('displays "None" when isShowingEpicsSwimlanes is false', () => {
      expect(wrapper.findComponent(GlDropdown).props('text')).toEqual('None');
    });

    it('returns "Epics" when isShowingEpicsSwimlanes is true', () => {
      store = new Vuex.Store({ state: { isShowingEpicsSwimlanes: true } });
      createComponent();
      expect(wrapper.findComponent(GlDropdown).props('text')).toEqual('Epic');
    });
  });

  describe('template', () => {
    it('renders .board-swimlanes-toggle-wrapper container', () => {
      expect(wrapper.find('[data-testid="toggle-swimlanes"]').exists()).toBe(true);
    });

    it('renders "Group by" label', () => {
      expect(wrapper.find('[data-testid="toggle-swimlanes-label"]').text()).toEqual('Group by');
    });

    it('renders dropdown with 2 options', () => {
      expect(wrapper.findComponent(GlDropdown).exists()).toBe(true);
      expect(wrapper.findAllComponents(GlDropdownItem).length).toEqual(2);
    });
  });
});
