import Vue, { nextTick } from 'vue';

import SidebarTodo from 'ee/epic/components/sidebar_items/sidebar_todo.vue';
import createStore from 'ee/epic/store';

import { mountComponentWithStore } from 'helpers/vue_mount_component_helper';
import { mockEpicMeta, mockEpicData } from '../../mock_data';

describe('SidebarTodoComponent', () => {
  const originalUserId = gon.current_user_id;
  let vm;
  let store;

  beforeEach(() => {
    gon.current_user_id = 1;

    const Component = Vue.extend(SidebarTodo);
    store = createStore();
    store.dispatch('setEpicMeta', mockEpicMeta);
    store.dispatch('setEpicData', mockEpicData);

    vm = mountComponentWithStore(Component, {
      store,
      props: { sidebarCollapsed: false },
    });
  });

  afterEach(() => {
    gon.current_user_id = originalUserId;
    vm.$destroy();
  });

  describe('template', () => {
    it('renders component container element with classes `block` & `todo` when `isUserSignedIn` & `sidebarCollapsed` is `true`', async () => {
      vm.sidebarCollapsed = true;

      await nextTick();
      expect(vm.$el.classList.contains('block')).toBe(true);
      expect(vm.$el.classList.contains('todo')).toBe(true);
    });

    it('renders Todo toggle button element', () => {
      const buttonEl = vm.$el.querySelector('button.btn-todo');

      expect(buttonEl).not.toBeNull();
      expect(buttonEl.dataset.issuableId).toBe('1');
      expect(buttonEl.dataset.issuableType).toBe('epic');
    });
  });
});
