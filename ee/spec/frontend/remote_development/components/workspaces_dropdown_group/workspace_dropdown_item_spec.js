import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkspaceDropdownItem from 'ee/remote_development/components/workspaces_dropdown_group/workspace_dropdown_item.vue';
import WorkspaceStateIndicator from 'ee/remote_development/components/common/workspace_state_indicator.vue';
import WorkspaceActions from 'ee/remote_development/components/common/workspace_actions.vue';
import { WORKSPACE_DESIRED_STATES } from 'ee/remote_development/constants';
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
  const findWorkspaceActions = () => wrapper.findComponent(WorkspaceActions);

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

    it('displays workspace actions', () => {
      expect(findWorkspaceActions().props()).toEqual({
        actualState: WORKSPACE.actualState,
        desiredState: WORKSPACE.desiredState,
        compact: true,
      });
    });
  });

  describe('when workspaces action is clicked', () => {
    it('emits updateWorkspace event with the desiredState provided by the action', () => {
      createWrapper();

      expect(wrapper.emitted('updateWorkspace')).toBe(undefined);

      findWorkspaceActions().vm.$emit('click', WORKSPACE_DESIRED_STATES.running);

      expect(wrapper.emitted('updateWorkspace')).toEqual([
        [{ desiredState: WORKSPACE_DESIRED_STATES.running }],
      ]);
    });
  });
});
