import { nextTick } from 'vue';
import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RoleSelect from 'ee/security_orchestration/components/policy_editor/scan_result_policy/role_select.vue';

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

  const createComponent = ({ provide = {} } = {}) => {
    wrapper = shallowMount(RoleSelect, {
      propsData: {
        existingApprovers: [],
      },
      provide: {
        namespacePath,
        roleApproverTypes,
        ...provide,
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
      findListbox().vm.$emit('select', [role]);
      await nextTick();
      expect(wrapper.emitted('updateSelectedApprovers')).toEqual([[[role]]]);
    });

    it('emits when a user is deselected', () => {
      const role = 'maintainer';
      findListbox().vm.$emit('select', [role]);
      findListbox().vm.$emit('select', []);
      expect(wrapper.emitted('updateSelectedApprovers')[1]).toEqual([[]]);
    });
  });
});
