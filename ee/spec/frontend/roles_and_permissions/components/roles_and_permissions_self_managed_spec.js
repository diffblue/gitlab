import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import GroupSelect from '~/vue_shared/components/entity_select/group_select.vue';
import ListMemberRoles from 'ee/roles_and_permissions/components/list_member_roles.vue';
import RolesAndPermissionsSelfManaged from 'ee/roles_and_permissions/components/roles_and_permissions_self_managed.vue';

describe('RolesAndPermissionsSelfManaged', () => {
  let wrapper;
  const createComponent = () => {
    wrapper = shallowMount(RolesAndPermissionsSelfManaged);
  };

  const findGroupSelect = () => wrapper.findComponent(GroupSelect);
  const findListMemberRoles = () => wrapper.findComponent(ListMemberRoles);

  beforeEach(() => {
    createComponent();
  });

  it('has a GroupSelect component', () => {
    expect(findGroupSelect().exists()).toBe(true);
  });

  it('has a `ListMemberRoles` component', () => {
    expect(findListMemberRoles().exists()).toBe(true);
  });

  it('correctly sets props to `ListMemberRoles`', async () => {
    expect(findListMemberRoles().props()).toMatchObject({
      emptyText: RolesAndPermissionsSelfManaged.i18n.emptyText,
      groupId: null,
    });

    const newGroupId = '36';
    findGroupSelect().vm.$emit('input', { value: newGroupId });
    await nextTick();

    expect(findListMemberRoles().props()).toMatchObject({
      emptyText: RolesAndPermissionsSelfManaged.i18n.emptyText,
      groupId: newGroupId,
    });
  });
});
