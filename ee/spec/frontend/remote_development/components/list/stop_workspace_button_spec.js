import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import StopWorkspaceButton, {
  i18n,
} from 'ee/remote_development/components/list/stop_workspace_button.vue';
import { WORKSPACE_STATES, WORKSPACE_DESIRED_STATES } from 'ee/remote_development/constants';

describe('StopWorkspaceButton', () => {
  let wrapper;

  const createWrapper = ({
    actualState = WORKSPACE_STATES.running,
    desiredState = WORKSPACE_STATES.running,
  } = {}) => {
    wrapper = shallowMount(StopWorkspaceButton, {
      propsData: {
        actualState,
        desiredState,
      },
    });
  };
  const findButton = () => wrapper.findComponent(GlButton);

  it.each`
    actualState                           | buttonVisibility | visibilityLabel
    ${WORKSPACE_STATES.running}           | ${true}          | ${'visible'}
    ${WORKSPACE_STATES.stopping}          | ${true}          | ${'visible'}
    ${WORKSPACE_STATES.failed}            | ${true}          | ${'hidden'}
    ${WORKSPACE_STATES.creationRequested} | ${false}         | ${'hidden'}
    ${WORKSPACE_STATES.starting}          | ${false}         | ${'hidden'}
    ${WORKSPACE_STATES.stopped}           | ${false}         | ${'hidden'}
    ${WORKSPACE_STATES.error}             | ${false}         | ${'hidden'}
    ${WORKSPACE_STATES.unknown}           | ${false}         | ${'hidden'}
    ${WORKSPACE_STATES.terminated}        | ${false}         | ${'hidden'}
  `(
    'button is $visibilityLabel when workspace actualState is $actualState',
    ({ buttonVisibility, actualState }) => {
      createWrapper({
        actualState,
        desiredState: WORKSPACE_STATES.running,
      });

      expect(findButton().exists()).toBe(buttonVisibility);
    },
  );

  it.each`
    desiredState                                 | buttonVisibility | visibilityLabel
    ${WORKSPACE_DESIRED_STATES.stopped}          | ${true}          | ${'visible'}
    ${WORKSPACE_DESIRED_STATES.running}          | ${true}          | ${'visible'}
    ${WORKSPACE_DESIRED_STATES.terminated}       | ${false}         | ${'hidden'}
    ${WORKSPACE_DESIRED_STATES.restartRequested} | ${false}         | ${'hidden'}
  `(
    'button is $visibilityLabel when workspace desiredState is $desiredState',
    ({ buttonVisibility, desiredState }) => {
      // These are the only actualStates where the stop button is visible. See the tests above
      [WORKSPACE_STATES.stopping, WORKSPACE_STATES.running].forEach((actualState) => {
        createWrapper({
          actualState,
          desiredState,
        });

        expect(findButton().exists()).toBe(buttonVisibility);
      });
    },
  );

  it('sets button as loading and disable when workspace desiredState is stopped', () => {
    createWrapper({
      desiredState: WORKSPACE_DESIRED_STATES.stopped,
    });

    expect(findButton().props().loading).toBe(true);
    expect(findButton().props().icon).toBe('stop');
    expect(findButton().props().disabled).toBe(true);
    expect(findButton().attributes('aria-label')).toBe(i18n.stoppingWorkspaceTooltip);
    expect(wrapper.find('span').attributes().title).toBe(i18n.stoppingWorkspaceTooltip);
  });

  it('emits click event when button is clicked', () => {
    createWrapper();

    findButton().vm.$emit('click');

    expect(wrapper.emitted('click')).toHaveLength(1);
  });
});
