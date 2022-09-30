import { mount } from '@vue/test-utils';

import TableBodyComponent from 'ee/group_member_contributions/components/table_body.vue';
import GroupMemberStore from 'ee/group_member_contributions/store/group_member_store';

import { rawMembers } from '../mock_data';

const createComponent = () => {
  const store = new GroupMemberStore();
  store.setMembers(rawMembers);
  const rows = store.members;

  return mount(TableBodyComponent, { propsData: { rows } });
};

describe('TableBodyComponent', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders row item element', () => {
    const rowEl = wrapper.find('tr');

    expect(rowEl.exists()).toBe(true);
    expect(rowEl.findAll('td')).toHaveLength(9);
  });

  it('renders username row cell element', () => {
    const cellEl = wrapper.find('td strong');

    expect(cellEl.exists()).toBe(true);
    expect(cellEl.find('a').attributes('href')).toBe(rawMembers[0].user_web_url);
  });
});
