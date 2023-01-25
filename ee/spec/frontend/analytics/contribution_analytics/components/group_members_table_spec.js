import { shallowMount } from '@vue/test-utils';
import { GlTable } from '@gitlab/ui';
import { stubComponent } from 'helpers/stub_component';
import GroupMembersTable from 'ee/analytics/contribution_analytics/components/group_members_table.vue';
import { MOCK_CONTRIBUTIONS } from '../mock_data';

describe('GroupMembersTable', () => {
  let wrapper;

  const createWrapper = () => {
    wrapper = shallowMount(GroupMembersTable, {
      propsData: {
        contributions: MOCK_CONTRIBUTIONS,
      },
      stubs: {
        GlTable: stubComponent(GlTable, {
          props: ['items', 'sortBy', 'sortDesc'],
        }),
      },
    });
  };

  const findTable = () => wrapper.findComponent(GlTable);

  beforeEach(() => {
    createWrapper();
  });

  it('renders a table with the contribution data', () => {
    expect(findTable().exists()).toBe(true);
    expect(findTable().props('items').length).toEqual(MOCK_CONTRIBUTIONS.length);
    expect(findTable().props('sortBy')).toEqual('user');
    expect(findTable().props('sortDesc')).toEqual(false);
  });
});
