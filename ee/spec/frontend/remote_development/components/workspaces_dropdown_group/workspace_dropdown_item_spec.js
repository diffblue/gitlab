import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { mockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkspaceDropdownItem from 'ee/remote_development/components/workspaces_dropdown_group/workspace_dropdown_item.vue';
import WorkspaceStateIndicator from 'ee/remote_development/components/common/workspace_state_indicator.vue';
import WorkspaceActions from 'ee/remote_development/components/common/workspace_actions.vue';
import { WORKSPACE_DESIRED_STATES } from 'ee/remote_development/constants';
import { WORKSPACE } from '../../mock_data';

describe('remote_development/components/workspaces_dropdown_group/workspace_dropdown_item.vue', () => {
  let wrapper;
  let trackingSpy;

  const createWrapper = () => {
    wrapper = shallowMountExtended(WorkspaceDropdownItem, {
      propsData: {
        workspace: WORKSPACE,
      },
    });

    trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
  };
  const findWorkspaceStateIndicator = () => wrapper.findComponent(WorkspaceStateIndicator);
  const findWorkspaceActions = () => wrapper.findComponent(WorkspaceActions);
  const findDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);

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

    it('passes workspace URL to the dropdown item', () => {
      expect(findDropdownItem().props().item).toEqual({
        text: WORKSPACE.name,
        href: WORKSPACE.url,
      });
    });

    it('displays workspace actions', () => {
      expect(findWorkspaceActions().props()).toEqual({
        actualState: WORKSPACE.actualState,
        desiredState: WORKSPACE.desiredState,
        compact: true,
      });
    });
  });

  describe('when the dropdown item emits "action" event', () => {
    beforeEach(() => {
      createWrapper();

      findDropdownItem().vm.$emit('action');
    });

    it('tracks event', () => {
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_consolidated_edit', {
        label: 'workspace',
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
