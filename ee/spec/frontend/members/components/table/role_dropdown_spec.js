import { GlCollapsibleListbox } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import LdapDropdownFooter from 'ee/members/components/action_dropdowns/ldap_dropdown_footer.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { member } from 'jest/members/mock_data';
import RoleDropdown from '~/members/components/table/role_dropdown.vue';
import { MEMBER_TYPES } from '~/members/constants';

describe('RoleDropdown', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = mount(RoleDropdown, {
      provide: {
        namespace: MEMBER_TYPES.user,
        group: {
          name: '',
          path: '',
        },
      },
      propsData: {
        member,
        permissions: {},
        ...propsData,
      },
    });

    return waitForPromises();
  };

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  describe('when member has `canOverride` permissions', () => {
    describe('when member is overridden', () => {
      it('renders LDAP dropdown footer', async () => {
        await createComponent({
          permissions: {
            canOverride: true,
          },
          member: { ...member, isOverridden: true },
        });

        expect(wrapper.findComponent(LdapDropdownFooter).exists()).toBe(true);
      });
    });

    describe('when member is not overridden', () => {
      it('disables dropdown', async () => {
        await createComponent({
          permissions: {
            canOverride: true,
          },
          member: { ...member, isOverridden: false },
        });

        expect(findListbox().props('disabled')).toBeDefined();
      });
    });
  });

  describe('when member does not have `canOverride` permissions', () => {
    it('does not render LDAP dropdown footer', async () => {
      await createComponent({
        permissions: {
          canOverride: false,
        },
      });

      expect(wrapper.findComponent(LdapDropdownFooter).exists()).toBe(false);
    });
  });
});
