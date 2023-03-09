import { mount } from '@vue/test-utils';
import SidebarHeader from 'ee/epic/components/sidebar_items/sidebar_header.vue';
import createStore from 'ee/epic/store';
import { mockEpicMeta, mockEpicData } from '../../mock_data';

describe('SidebarHeaderComponent', () => {
  let wrapper;
  let store;

  beforeEach(() => {
    store = createStore();
    store.dispatch('setEpicMeta', mockEpicMeta);
    store.dispatch('setEpicData', mockEpicData);

    wrapper = mount(SidebarHeader, {
      store,
      propsData: { sidebarCollapsed: false },
    });
  });

  describe('template', () => {
    it('renders component container element with classes `block` & `issuable-sidebar-header`', () => {
      expect(wrapper.classes('block')).toBe(true);
      expect(wrapper.classes('issuable-sidebar-header')).toBe(true);
    });

    it('renders toggle sidebar button element', () => {
      expect(wrapper.find('button.btn-sidebar-action').exists()).toBe(true);
    });
  });
});
