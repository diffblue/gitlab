import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import StartWorkspaceButton, {
  i18n,
} from 'ee/remote_development/components/list/start_workspace_button.vue';
import { WORKSPACE_STATES, WORKSPACE_DESIRED_STATES } from 'ee/remote_development/constants';

describe('StartWorkspaceButton', () => {
  let wrapper;

  const createWrapper = ({
    actualState = WORKSPACE_STATES.running,
    desiredState = WORKSPACE_STATES.running,
  } = {}) => {
    wrapper = shallowMount(StartWorkspaceButton, {
      propsData: {
        actualState,
        desiredState,
      },
    });
  };
  const findButton = () => wrapper.findComponent(GlButton);

  it.each`
    actualState                    | buttonVisibility | visibilityLabel
    ${WORKSPACE_STATES.stopped}    | ${true}          | ${'visible'}
    ${WORKSPACE_STATES.starting}   | ${true}          | ${'visible'}
    ${WORKSPACE_STATES.running}    | ${false}         | ${'hidden'}
    ${WORKSPACE_STATES.creating}   | ${false}         | ${'hidden'}
    ${WORKSPACE_STATES.stopping}   | ${false}         | ${'hidden'}
    ${WORKSPACE_STATES.error}      | ${false}         | ${'hidden'}
    ${WORKSPACE_STATES.failed}     | ${false}         | ${'hidden'}
    ${WORKSPACE_STATES.unknown}    | ${false}         | ${'hidden'}
    ${WORKSPACE_STATES.terminated} | ${false}         | ${'hidden'}
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
    desiredState                           | buttonVisibility | visibilityLabel
    ${WORKSPACE_DESIRED_STATES.stopped}    | ${true}          | ${'visible'}
    ${WORKSPACE_DESIRED_STATES.running}    | ${true}          | ${'visible'}
    ${WORKSPACE_DESIRED_STATES.terminated} | ${false}         | ${'hidden'}
    ${WORKSPACE_DESIRED_STATES.restarting} | ${false}         | ${'hidden'}
  `(
    'button is $visibilityLabel when workspace desiredState is $desiredState',
    ({ buttonVisibility, desiredState }) => {
      // These are the only actualStates where the start button is visible. See the tests above
      [WORKSPACE_STATES.stopped, WORKSPACE_STATES.starting].forEach((actualState) => {
        createWrapper({
          actualState,
          desiredState,
        });

        expect(findButton().exists()).toBe(buttonVisibility);
      });
    },
  );

  it('sets button as as loading and disabled when workspace desiredState is running', () => {
    createWrapper({
      actualState: WORKSPACE_STATES.stopped,
      desiredState: WORKSPACE_DESIRED_STATES.running,
    });

    expect(findButton().props().loading).toBe(true);
    expect(findButton().props().disabled).toBe(true);
    expect(findButton().props().icon).toBe('play');
    expect(findButton().attributes('aria-label')).toBe(i18n.startingWorkspaceTooltip);
    expect(wrapper.find('span').attributes().title).toBe(i18n.startingWorkspaceTooltip);
  });

  it('emits click event when button is clicked', () => {
    createWrapper({ actualState: WORKSPACE_STATES.stopped });

    findButton().vm.$emit('click');

    expect(wrapper.emitted('click')).toHaveLength(1);
  });
});
