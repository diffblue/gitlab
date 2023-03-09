import { shallowMount } from '@vue/test-utils';
import { GlLabel } from '@gitlab/ui';
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
    provide: {
      currentGroupVisibility: 'private',
    },
  });
};

describe('GroupItemComponent', () => {
  let wrapper;

  const findComplianceFrameworkLabel = () => wrapper.findComponent(GlLabel);

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

      expect(findComplianceFrameworkLabel().props()).toMatchObject({
        backgroundColor: color,
        description,
        title: name,
        size: 'sm',
      });
    });
  });
});
