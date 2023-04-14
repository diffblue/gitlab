import { mount } from '@vue/test-utils';

import SidebarTodo from 'ee/epic/components/sidebar_items/sidebar_todo.vue';
import createStore from 'ee/epic/store';

import { mockEpicMeta, mockEpicData } from '../../mock_data';

describe('SidebarTodoComponent', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    const store = createStore();
    store.dispatch('setEpicMeta', mockEpicMeta);
    store.dispatch('setEpicData', mockEpicData);

    return mount(SidebarTodo, {
      store,
      propsData: { sidebarCollapsed: false, ...propsData },
    });
  };

  beforeEach(() => {
    gon.current_user_id = 1;
  });

  describe('when `isUserSignedIn` & `sidebarCollapsed` is `true`', () => {
    it('renders component container element with classes `block` & `todo`', () => {
      wrapper = createComponent({ sidebarCollapsed: true });

      expect(wrapper.classes('block')).toBe(true);
      expect(wrapper.classes('todo')).toBe(true);
    });
  });

  it('renders Todo toggle button element', () => {
    wrapper = createComponent();

    const buttonWrapper = wrapper.find('button.btn-todo');

    expect(buttonWrapper.exists()).toBe(true);
    expect(buttonWrapper.attributes()).toMatchObject({
      'aria-label': 'Add a to do',
      'data-issuable-id': mockEpicMeta.epicId.toString(),
      'data-issuable-type': 'epic',
    });
  });
});
