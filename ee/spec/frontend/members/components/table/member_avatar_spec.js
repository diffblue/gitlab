import { shallowMount } from '@vue/test-utils';
import UserAvatar from '~/members/components/avatars/user_avatar.vue';
import MemberAvatar from '~/members/components/table/member_avatar.vue';
import { MEMBER_TYPES } from 'ee_else_ce/members/constants';
import { bannedMember } from 'ee_else_ce_jest/members/mock_data';

describe('MemberAvatar', () => {
  let wrapper;

  const createComponent = (propsData) => {
    wrapper = shallowMount(MemberAvatar, {
      propsData: { isCurrentUser: false, ...propsData },
    });
  };

  it('renders UserAvatar', () => {
    createComponent({ memberType: MEMBER_TYPES.banned, member: bannedMember });

    expect(wrapper.findComponent(UserAvatar).exists()).toBe(true);
  });
});
