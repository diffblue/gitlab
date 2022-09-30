import { mount } from '@vue/test-utils';

import AppComponent from 'ee/group_member_contributions/components/app.vue';
import GroupMemberStore from 'ee/group_member_contributions/store/group_member_store';
import { contributionsPath } from '../mock_data';

describe('AppComponent', () => {
  let wrapper;

  const createStore = (state = {}) => {
    const store = new GroupMemberStore(contributionsPath);

    Object.assign(store.state, state);

    return store;
  };

  const createComponent = (store = createStore()) => {
    wrapper = mount(AppComponent, { propsData: { store } });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders component container element with class `group-member-contributions-container`', () => {
    createComponent();

    expect(wrapper.classes()).toContain('group-member-contributions-container');
  });

  it('renders header title element within component container', () => {
    createComponent();

    expect(wrapper.find('h3').text()).toBe('Contributions per group member');
  });

  it('shows loading icon when isLoading prop is true', () => {
    const store = createStore({ isLoading: true });
    createComponent(store);
    const loadingEl = wrapper.find('.loading-animation');

    expect(loadingEl.exists()).toBe(true);
    expect(loadingEl.find('span').attributes('aria-label')).toBe(
      'Loading contribution stats for group members',
    );
  });

  it('renders table container element', () => {
    const store = createStore({ isLoading: false });
    createComponent(store);

    expect(wrapper.find('table.table.gl-sortable').exists()).toBe(true);
  });

  it('calls store.sortMembers with columnName param', async () => {
    const store = createStore({ isLoading: false });
    jest.spyOn(store, 'sortMembers').mockImplementation(() => {});
    createComponent(store);

    const firstColumnName = 'fullname';
    await wrapper.find('th').trigger('click');

    expect(store.sortMembers).toHaveBeenCalledWith(firstColumnName);
  });
});
