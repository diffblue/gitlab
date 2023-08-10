import { shallowMount } from '@vue/test-utils';
import { GlBadge } from '@gitlab/ui';
import WorkspaceStateIndicator, {
  i18n,
} from 'ee/remote_development/components/common/workspace_state_indicator.vue';
import { WORKSPACE_STATES } from 'ee/remote_development/constants';

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
    workspaceState                        | iconName    | label                                              | variant
    ${WORKSPACE_STATES.creationRequested} | ${'status'} | ${i18n.labels[WORKSPACE_STATES.creationRequested]} | ${'success'}
    ${WORKSPACE_STATES.starting}          | ${'status'} | ${i18n.labels[WORKSPACE_STATES.starting]}          | ${'success'}
    ${WORKSPACE_STATES.running}           | ${''}       | ${i18n.labels[WORKSPACE_STATES.running]}           | ${'success'}
    ${WORKSPACE_STATES.stopping}          | ${'status'} | ${i18n.labels[WORKSPACE_STATES.stopping]}          | ${'info'}
    ${WORKSPACE_STATES.stopped}           | ${''}       | ${i18n.labels[WORKSPACE_STATES.stopped]}           | ${'info'}
    ${WORKSPACE_STATES.failed}            | ${''}       | ${i18n.labels[WORKSPACE_STATES.failed]}            | ${'danger'}
    ${WORKSPACE_STATES.error}             | ${''}       | ${i18n.labels[WORKSPACE_STATES.error]}             | ${'danger'}
    ${WORKSPACE_STATES.unknown}           | ${''}       | ${i18n.labels[WORKSPACE_STATES.unknown]}           | ${'danger'}
    ${WORKSPACE_STATES.terminating}       | ${'status'} | ${i18n.labels[WORKSPACE_STATES.terminating]}       | ${'muted'}
    ${WORKSPACE_STATES.terminated}        | ${''}       | ${i18n.labels[WORKSPACE_STATES.terminated]}        | ${'muted'}
  `(
    'displays $iconName with $tooltip and $cssClass when workspace state is $state',
    ({ workspaceState, iconName, label, variant }) => {
      createWrapper({ workspaceState });

      const badge = wrapper.findComponent(GlBadge);

      expect(badge.props()).toEqual({
        icon: iconName,
        iconSize: 'md',
        size: 'md',
        variant,
      });
      expect(badge.text()).toBe(label);
    },
  );
});
