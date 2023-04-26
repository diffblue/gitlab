import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import RestartWorkspaceButton, {
  i18n,
} from 'ee/remote_development/components/list/restart_workspace_button.vue';
import { WORKSPACE_STATES, WORKSPACE_DESIRED_STATES } from 'ee/remote_development/constants';

describe('RestartWorkspaceButton', () => {
  let wrapper;

  const createWrapper = ({
    actualState = WORKSPACE_STATES.running,
    desiredState = WORKSPACE_STATES.running,
  } = {}) => {
    wrapper = shallowMount(RestartWorkspaceButton, {
      propsData: {
        actualState,
        desiredState,
      },
    });
  };
  const findButton = () => wrapper.findComponent(GlButton);

  // The * represents a universal quantifier. The button is hidden for every desired state
  it.each`
    actualState                    | desiredState                           | buttonVisibility | visibilityLabel
    ${WORKSPACE_STATES.running}    | ${WORKSPACE_DESIRED_STATES.restarting} | ${true}          | ${'visible'}
    ${WORKSPACE_STATES.running}    | ${WORKSPACE_DESIRED_STATES.running}    | ${true}          | ${'visible'}
    ${WORKSPACE_STATES.running}    | ${WORKSPACE_DESIRED_STATES.stopped}    | ${false}         | ${'hidden'}
    ${WORKSPACE_STATES.running}    | ${WORKSPACE_DESIRED_STATES.terminated} | ${false}         | ${'hidden'}
    ${WORKSPACE_STATES.stopped}    | ${WORKSPACE_DESIRED_STATES.restarting} | ${true}          | ${'visible'}
    ${WORKSPACE_STATES.stopped}    | ${WORKSPACE_DESIRED_STATES.stopped}    | ${true}          | ${'visible'}
    ${WORKSPACE_STATES.stopped}    | ${WORKSPACE_DESIRED_STATES.running}    | ${false}         | ${'hidden'}
    ${WORKSPACE_STATES.stopped}    | ${WORKSPACE_DESIRED_STATES.terminated} | ${false}         | ${'hidden'}
    ${WORKSPACE_STATES.failed}     | ${WORKSPACE_DESIRED_STATES.restarting} | ${true}          | ${'visible'}
    ${WORKSPACE_STATES.failed}     | ${WORKSPACE_DESIRED_STATES.running}    | ${true}          | ${'visible'}
    ${WORKSPACE_STATES.failed}     | ${WORKSPACE_DESIRED_STATES.stopped}    | ${false}         | ${'hidden'}
    ${WORKSPACE_STATES.failed}     | ${WORKSPACE_DESIRED_STATES.terminated} | ${false}         | ${'hidden'}
    ${WORKSPACE_STATES.starting}   | ${'*'}                                 | ${false}         | ${'hidden'}
    ${WORKSPACE_STATES.creating}   | ${'*'}                                 | ${false}         | ${'hidden'}
    ${WORKSPACE_STATES.stopping}   | ${'*'}                                 | ${false}         | ${'hidden'}
    ${WORKSPACE_STATES.terminated} | ${'*'}                                 | ${false}         | ${'hidden'}
    ${WORKSPACE_STATES.error}      | ${'*'}                                 | ${false}         | ${'hidden'}
    ${WORKSPACE_STATES.unknown}    | ${'*'}                                 | ${false}         | ${'hidden'}
  `(
    'button is $visibilityLabel when workspace actualState is $actualState and desiredState is $desiredState',
    ({ buttonVisibility, actualState, desiredState }) => {
      createWrapper({
        actualState,
        desiredState,
      });

      expect(findButton().exists()).toBe(buttonVisibility);
    },
  );

  it('sets button as loading and disabled when workspace desiredState is restarting', () => {
    createWrapper({
      desiredState: WORKSPACE_DESIRED_STATES.restarting,
    });

    expect(findButton().props().loading).toBe(true);
    expect(findButton().props().disabled).toBe(true);
    expect(findButton().props().icon).toBe('retry');
    expect(findButton().attributes('aria-label')).toBe(i18n.restartingWorkspaceTooltip);
    expect(wrapper.find('span').attributes().title).toBe(i18n.restartingWorkspaceTooltip);
  });

  it('emits click event when button is clicked', () => {
    createWrapper();

    findButton().vm.$emit('click');

    expect(wrapper.emitted('click')).toHaveLength(1);
  });
});
