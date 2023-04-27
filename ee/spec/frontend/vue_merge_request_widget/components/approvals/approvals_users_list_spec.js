import { shallowMount } from '@vue/test-utils';
import ApprovalsUsersList from 'ee/vue_merge_request_widget/components/approvals/approvals_users_list.vue';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';

const label = 'Some label';
const users = ['user1', 'user2'];

describe('ApprovalsUsersList', () => {
  let wrapper;

  const findUserAvatarList = () => wrapper.findComponent(UserAvatarList);

  const createComponent = () => {
    wrapper = shallowMount(ApprovalsUsersList, {
      propsData: {
        label,
        users,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders the label', () => {
    expect(wrapper.text()).toContain(label);
  });

  it('passes the users to the avatars list', () => {
    expect(findUserAvatarList().props('items')).toEqual(users);
  });
});
