import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RoleSelect from 'ee/security_orchestration/components/policy_editor/scan_result/action/role_select.vue';

const roleCounts = {
  developer: 3,
  guest: 4,
  maintainer: 2,
  owner: 1,
  reporter: 5,
};

const roleApproverTypes = Object.keys(roleCounts);

describe('RoleSelect component', () => {
  let wrapper;
  const namespacePath = 'path/to/namespace';

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMount(RoleSelect, {
      propsData: {
        existingApprovers: [],
        ...propsData,
      },
      provide: {
        namespacePath,
        roleApproverTypes,
      },
    });
  };

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('emits when a role is selected', async () => {
      const role = 'owner';
      await findListbox().vm.$emit('select', [role]);
      expect(wrapper.emitted('updateSelectedApprovers')).toEqual([[[role]]]);
    });

    it('displays the correct listbox toggle class', () => {
      expect(findListbox().props('toggleClass')).toEqual([
        'gl-max-w-26',
        { 'gl-inset-border-1-red-500!': false },
      ]);
    });

    it('displays the correct toggle text', () => {
      expect(findListbox().props('toggleText')).toBe('Choose specific role');
    });

    it('does not emit an error', () => {
      expect(wrapper.emitted('error')).toEqual(undefined);
    });
  });

  describe('custom props', () => {
    beforeEach(() => {
      createComponent({ propsData: { state: false } });
    });

    it('displays the correct listbox toggle class', () => {
      expect(findListbox().props('toggleClass')).toEqual([
        'gl-max-w-26',
        { 'gl-inset-border-1-red-500!': true },
      ]);
    });
  });

  describe('with valid approvers', () => {
    const role = { text: 'Developer', value: 'developer' };

    beforeEach(() => {
      createComponent({ propsData: { existingApprovers: [role.value] } });
    });

    it('displays the correct toggle text', () => {
      expect(findListbox().props('toggleText')).toBe(role.text);
    });

    it('emits when a user is deselected', () => {
      findListbox().vm.$emit('select', []);
      expect(wrapper.emitted('updateSelectedApprovers')).toEqual([[[]]]);
    });

    it('does not emit an error', () => {
      expect(wrapper.emitted('error')).toEqual(undefined);
    });
  });

  describe('with invalid approvers', () => {
    const validRole = 'developer';
    const invalidRole = 'invalid';

    it('displays the correct toggle text', () => {
      createComponent({ propsData: { existingApprovers: [invalidRole] } });
      expect(findListbox().props('toggleText')).toBe('Choose specific role');
    });

    it('emits an error when a user updates to an invalid role', async () => {
      createComponent({ propsData: { existingApprovers: [validRole] } });
      await wrapper.setProps({ existingApprovers: [invalidRole] });
      expect(wrapper.emitted('error')).toEqual([[]]);
    });
  });
});
