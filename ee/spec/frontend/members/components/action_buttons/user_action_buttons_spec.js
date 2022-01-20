import { shallowMount } from '@vue/test-utils';
import LdapOverrideButton from 'ee/members/components/ldap/ldap_override_button.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { member } from 'jest/members/mock_data';
import UserActionButtons from '~/members/components/action_buttons/user_action_buttons.vue';
import { MEMBER_TYPES } from '~/members/constants';

describe('UserActionButtons', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(UserActionButtons, {
      provide: {
        namespace: MEMBER_TYPES.user,
      },
      propsData: {
        member,
        isCurrentUser: false,
        isInvitedUser: false,
        ...propsData,
      },
    });

    return waitForPromises();
  };

  const findLdapOverrideButton = () => wrapper.findComponent(LdapOverrideButton);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when member has `canOverride` permissions', () => {
    describe('when member is not overridden', () => {
      it('renders LDAP override button', async () => {
        await createComponent({
          permissions: { canOverride: true },
          member: {
            ...member,
            isOverridden: false,
          },
        });

        expect(findLdapOverrideButton().exists()).toBe(true);
      });
    });

    describe('when member is overridden', () => {
      it('does not render the LDAP override button', async () => {
        await createComponent({
          permissions: { canOverride: true },
          member: {
            ...member,
            isOverridden: true,
          },
        });

        expect(findLdapOverrideButton().exists()).toBe(false);
      });
    });
  });

  describe('when member does not have `canOverride` permissions', () => {
    it('does not render the LDAP override button', async () => {
      await createComponent({
        permissions: { canOverride: false },
      });

      expect(findLdapOverrideButton().exists()).toBe(false);
    });
  });
});
