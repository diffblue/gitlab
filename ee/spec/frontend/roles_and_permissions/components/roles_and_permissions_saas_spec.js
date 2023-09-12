import { shallowMount } from '@vue/test-utils';
import ListMemberRoles from 'ee/roles_and_permissions/components/list_member_roles.vue';
import RolesAndPermissionsSaas from 'ee/roles_and_permissions/components/roles_and_permissions_saas.vue';

describe('RolesAndPermissionsSaas', () => {
  let wrapper;
  const createComponent = () => {
    wrapper = shallowMount(RolesAndPermissionsSaas, { propsData: { groupId: '31' } });
  };

  const findListMemberRoles = () => wrapper.findComponent(ListMemberRoles);

  beforeEach(() => {
    createComponent();
  });

  it('correctly sets props to ListMemberRoles', () => {
    const memberRoles = findListMemberRoles();
    expect(memberRoles.exists()).toBe(true);
    expect(memberRoles.props()).toMatchObject({
      groupId: '31',
      emptyText: RolesAndPermissionsSaas.i18n.emptyText,
    });
  });
});
