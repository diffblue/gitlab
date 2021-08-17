import Vue from 'vue';

import SidebarHeader from 'ee/epic/components/sidebar_items/sidebar_header.vue';
import createStore from 'ee/epic/store';

import { mountComponentWithStore } from 'helpers/vue_mount_component_helper';
import { mockEpicMeta, mockEpicData } from '../../mock_data';

describe('SidebarHeaderComponent', () => {
  let vm;
  let store;

  beforeEach(() => {
    const Component = Vue.extend(SidebarHeader);
    store = createStore();
    store.dispatch('setEpicMeta', mockEpicMeta);
    store.dispatch('setEpicData', mockEpicData);

    vm = mountComponentWithStore(Component, {
      store,
      props: { sidebarCollapsed: false },
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('template', () => {
    it('renders component container element with classes `block` & `issuable-sidebar-header`', () => {
      expect(vm.$el.classList.contains('block')).toBe(true);
      expect(vm.$el.classList.contains('issuable-sidebar-header')).toBe(true);
    });

    it('renders toggle sidebar button element', () => {
      expect(vm.$el.querySelector('button.btn-sidebar-action')).not.toBeNull();
    });
  });
});
