import { mount } from '@vue/test-utils';

import GroupMembers from 'ee/analytics/contribution_analytics/group_members';
import GroupMembersTable from 'ee/analytics/contribution_analytics/components/group_members_table.vue';
import { CONTRIBUTIONS_PATH } from '../mock_data';

describe('GroupMembersTable', () => {
  let wrapper;

  const createComponent = ({ isLoading = false } = {}) => {
    jest.spyOn(GroupMembers.prototype, 'fetchContributedMembers').mockImplementation(() => {});
    jest.spyOn(GroupMembers.prototype, 'isLoading', 'get').mockReturnValue(isLoading);
    wrapper = mount(GroupMembersTable, {
      provide: { memberContributionsPath: CONTRIBUTIONS_PATH },
    });
  };

  it('renders component container element with class `group-member-contributions-container`', () => {
    createComponent();
    expect(wrapper.classes()).toContain('group-member-contributions-container');
  });

  it('renders header title element within component container', () => {
    createComponent();
    expect(wrapper.find('h3').text()).toBe('Contributions per group member');
  });

  it('shows loading icon when isLoading prop is true', () => {
    createComponent({ isLoading: true });
    const loadingEl = wrapper.find('.loading-animation');

    expect(loadingEl.exists()).toBe(true);
    expect(loadingEl.find('span').attributes('aria-label')).toBe(
      'Loading contribution stats for group members',
    );
  });

  it('renders table container element', () => {
    createComponent();
    expect(wrapper.find('table.table.gl-sortable').exists()).toBe(true);
  });

  it('calls store.sortMembers with columnName param', async () => {
    createComponent();
    const sortMembers = jest
      .spyOn(GroupMembers.prototype, 'sortMembers')
      .mockImplementation(() => {});

    const firstColumnName = 'fullname';
    await wrapper.find('th').trigger('click');
    expect(sortMembers).toHaveBeenCalledWith(firstColumnName);
  });
});
