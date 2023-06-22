import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkspaceDropdownItem from 'ee/remote_development/components/workspaces_dropdown_group/workspace_dropdown_item.vue';
import WorkspaceStateIndicator from 'ee/remote_development/components/common/workspace_state_indicator.vue';
import { WORKSPACE } from '../../mock_data';

describe('remote_development/components/workspaces_dropdown_group/workspace_dropdown_item.vue', () => {
  let wrapper;

  const createWrapper = () => {
    wrapper = shallowMountExtended(WorkspaceDropdownItem, {
      propsData: {
        workspace: WORKSPACE,
      },
    });
  };
  const findWorkspaceStateIndicator = () => wrapper.findComponent(WorkspaceStateIndicator);

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('displays workspace state indicator', () => {
      expect(findWorkspaceStateIndicator().props().workspaceState).toBe(WORKSPACE.actualState);
    });

    it('displays the workspace name', () => {
      expect(wrapper.text()).toContain(WORKSPACE.name);
    });
  });
});
