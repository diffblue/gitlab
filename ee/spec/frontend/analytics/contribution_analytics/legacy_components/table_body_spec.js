import { mount } from '@vue/test-utils';

import TableBodyComponent from 'ee/analytics/contribution_analytics/legacy_components/table_body.vue';
import GroupMembers from 'ee/analytics/contribution_analytics/group_members';

import { MOCK_MEMBERS } from '../mock_data';

const createComponent = () => {
  const store = new GroupMembers();
  store.setMembers(MOCK_MEMBERS);
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
    expect(cellEl.find('a').attributes('href')).toBe(MOCK_MEMBERS[0].user_web_url);
  });
});
