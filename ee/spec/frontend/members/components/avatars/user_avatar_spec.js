import { GlBadge } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { member as memberMock } from 'jest/members/mock_data';
import UserAvatar from '~/members/components/avatars/user_avatar.vue';

describe('UserAvatar', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = mount(UserAvatar, {
      propsData: {
        isCurrentUser: false,
        ...propsData,
      },
      provide: {
        canManageMembers: true,
      },
    });
  };

  describe('badges', () => {
    it.each`
      member                                          | badgeText
      ${{ ...memberMock, usingLicense: true }}        | ${'Is using seat'}
      ${{ ...memberMock, groupSso: true }}            | ${'SAML'}
      ${{ ...memberMock, groupManagedAccount: true }} | ${'Managed Account'}
      ${{ ...memberMock, canOverride: true }}         | ${'LDAP'}
    `('renders the "$badgeText" badge', ({ member, badgeText }) => {
      createComponent({ member });

      expect(wrapper.findComponent(GlBadge).text()).toBe(badgeText);
    });
  });
});
