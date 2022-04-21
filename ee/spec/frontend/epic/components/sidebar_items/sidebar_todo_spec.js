import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';

import SidebarTodo from 'ee/epic/components/sidebar_items/sidebar_todo.vue';
import createStore from 'ee/epic/store';

import { mockEpicMeta, mockEpicData } from '../../mock_data';

describe('SidebarTodoComponent', () => {
  const originalUserId = gon.current_user_id;
  let wrapper;
  let store;

  beforeEach(() => {
    gon.current_user_id = 1;

    store = createStore();
    store.dispatch('setEpicMeta', mockEpicMeta);
    store.dispatch('setEpicData', mockEpicData);

    wrapper = mount(SidebarTodo, {
      store,
      props: { sidebarCollapsed: false },
    });
  });

  afterEach(() => {
    gon.current_user_id = originalUserId;
    wrapper.destroy();
  });

  describe('template', () => {
    it('renders component container element with classes `block` & `todo` when `isUserSignedIn` & `sidebarCollapsed` is `true`', async () => {
      wrapper.setProps({ sidebarCollapsed: true });

      await nextTick();
      expect(wrapper.classes('block')).toBe(true);
      expect(wrapper.classes('todo')).toBe(true);
    });

    it('renders Todo toggle button element', () => {
      const buttonWrapper = wrapper.find('button.btn-todo');

      expect(buttonWrapper.exists()).toBe(true);
      expect(buttonWrapper.attributes()).toMatchObject({
        'aria-label': 'Add a to do',
        'data-issuable-id': '1',
        'data-issuable-type': 'epic',
      });
    });
  });
});
