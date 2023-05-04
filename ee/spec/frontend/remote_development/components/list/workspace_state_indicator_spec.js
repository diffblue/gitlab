import { shallowMount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
import WorkspaceStateIndicator, {
  i18n,
} from 'ee/remote_development/components/list/workspace_state_indicator.vue';
import {
  WORKSPACE_STATES,
  FILL_CLASS_GREEN,
  FILL_CLASS_ORANGE,
  FILL_CLASS_RED,
} from 'ee/remote_development/constants';

describe('WorkspaceStateIndicator', () => {
  let wrapper;

  const createWrapper = ({ workspaceState }) => {
    wrapper = shallowMount(WorkspaceStateIndicator, {
      propsData: {
        workspaceState,
      },
    });
  };

  it.each`
    workspaceState                        | iconName              | tooltip                                              | cssClass
    ${WORKSPACE_STATES.creationRequested} | ${'status-running'}   | ${i18n.tooltips[WORKSPACE_STATES.creationRequested]} | ${FILL_CLASS_GREEN}
    ${WORKSPACE_STATES.starting}          | ${'status-running'}   | ${i18n.tooltips[WORKSPACE_STATES.starting]}          | ${FILL_CLASS_GREEN}
    ${WORKSPACE_STATES.running}           | ${'status-active'}    | ${i18n.tooltips[WORKSPACE_STATES.running]}           | ${FILL_CLASS_GREEN}
    ${WORKSPACE_STATES.stopping}          | ${'status-running'}   | ${i18n.tooltips[WORKSPACE_STATES.stopping]}          | ${null}
    ${WORKSPACE_STATES.stopped}           | ${'status-stopped'}   | ${i18n.tooltips[WORKSPACE_STATES.stopped]}           | ${null}
    ${WORKSPACE_STATES.failed}            | ${'status_warning'}   | ${i18n.tooltips[WORKSPACE_STATES.failed]}            | ${FILL_CLASS_ORANGE}
    ${WORKSPACE_STATES.error}             | ${'status_warning'}   | ${i18n.tooltips[WORKSPACE_STATES.error]}             | ${FILL_CLASS_ORANGE}
    ${WORKSPACE_STATES.unknown}           | ${'status_warning'}   | ${i18n.tooltips[WORKSPACE_STATES.unknown]}           | ${FILL_CLASS_ORANGE}
    ${WORKSPACE_STATES.terminating}       | ${'status-running'}   | ${i18n.tooltips[WORKSPACE_STATES.terminating]}       | ${FILL_CLASS_RED}
    ${WORKSPACE_STATES.terminated}        | ${'status-cancelled'} | ${i18n.tooltips[WORKSPACE_STATES.terminated]}        | ${FILL_CLASS_RED}
  `(
    'displays $iconName with $tooltip and $cssClass when workspace state is $state',
    ({ workspaceState, iconName, tooltip, cssClass }) => {
      createWrapper({ workspaceState });

      const icon = wrapper.findComponent(GlIcon);

      expect(icon.props()).toEqual({
        name: iconName,
        size: 12,
        ariaLabel: tooltip,
      });
      expect(icon.attributes().title).toBe(tooltip);

      if (cssClass) {
        expect(icon.classes()).toContain(cssClass);
      } else {
        expect(icon.classes()).toHaveLength(1);
      }
    },
  );
});
