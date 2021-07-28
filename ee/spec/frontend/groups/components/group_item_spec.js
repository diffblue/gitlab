import { shallowMount } from '@vue/test-utils';
import ComplianceFrameworkLabel from 'ee_component/vue_shared/components/compliance_framework_label/compliance_framework_label.vue';
import waitForPromises from 'helpers/wait_for_promises';
import GroupFolder from '~/groups/components/group_folder.vue';
import GroupItem from '~/groups/components/group_item.vue';
import { mockParentGroupItem, mockChildren } from '../mock_data';

const createComponent = (props = {}) => {
  return shallowMount(GroupItem, {
    propsData: {
      parentGroup: mockParentGroupItem,
      ...props,
    },
    components: { GroupFolder },
  });
};

describe('GroupItemComponent', () => {
  let wrapper;

  const findComplianceFrameworkLabel = () => wrapper.findComponent(ComplianceFrameworkLabel);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Compliance framework label', () => {
    it('does not render if the item does not have a compliance framework', async () => {
      wrapper = createComponent({ group: mockChildren[0] });
      await waitForPromises();

      expect(findComplianceFrameworkLabel().exists()).toBe(false);
    });

    it('renders if the item has a compliance framework', async () => {
      const { color, description, name } = mockChildren[1].complianceFramework;

      wrapper = createComponent({ group: mockChildren[1] });
      await waitForPromises();

      expect(findComplianceFrameworkLabel().props()).toStrictEqual({
        color,
        description,
        name,
      });
    });
  });
});
