import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import TerminateWorkspaceButton, {
  i18n,
} from 'ee/remote_development/components/list/terminate_workspace_button.vue';
import { WORKSPACE_STATES, WORKSPACE_DESIRED_STATES } from 'ee/remote_development/constants';

describe('TerminateWorkspaceButton', () => {
  let wrapper;

  const createWrapper = ({
    actualState = WORKSPACE_STATES.running,
    desiredState = WORKSPACE_STATES.running,
  } = {}) => {
    wrapper = shallowMount(TerminateWorkspaceButton, {
      propsData: {
        actualState,
        desiredState,
      },
    });
  };
  const findButton = () => wrapper.findComponent(GlButton);

  it.each`
    actualState                           | buttonVisibility | visibilityLabel
    ${WORKSPACE_STATES.creationRequested} | ${true}          | ${'visible'}
    ${WORKSPACE_STATES.starting}          | ${true}          | ${'visible'}
    ${WORKSPACE_STATES.running}           | ${true}          | ${'visible'}
    ${WORKSPACE_STATES.stopping}          | ${true}          | ${'visible'}
    ${WORKSPACE_STATES.stopped}           | ${true}          | ${'visible'}
    ${WORKSPACE_STATES.error}             | ${true}          | ${'visible'}
    ${WORKSPACE_STATES.failed}            | ${true}          | ${'visible'}
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
    desiredState                                 | buttonProps                                                                                   | buttonStateDesc
    ${WORKSPACE_DESIRED_STATES.terminated}       | ${{ loading: true, disabled: true, title: i18n.terminatingWorkspaceTooltip, icon: 'remove' }} | ${'disabled and loading'}
    ${WORKSPACE_DESIRED_STATES.running}          | ${{ loading: false, disabled: false, title: i18n.terminateWorkspaceTooltip, icon: 'remove' }} | ${'enabled and not loading'}
    ${WORKSPACE_DESIRED_STATES.stopped}          | ${{ loading: false, disabled: false, title: i18n.terminateWorkspaceTooltip, icon: 'remove' }} | ${'enabled and not loading'}
    ${WORKSPACE_DESIRED_STATES.restartRequested} | ${{ loading: false, disabled: false, title: i18n.terminateWorkspaceTooltip, icon: 'remove' }} | ${'enabled and not loading'}
  `(
    'sets button as $buttonStateDesc when workspace desiredState is $desiredState',
    ({ desiredState, buttonProps }) => {
      createWrapper({
        desiredState,
      });

      expect(findButton().props().loading).toBe(buttonProps.loading);
      expect(findButton().props().icon).toBe(buttonProps.icon);
      expect(findButton().props().disabled).toBe(buttonProps.disabled);
      expect(findButton().attributes('aria-label')).toBe(buttonProps.title);

      expect(wrapper.find('span').attributes().title).toBe(buttonProps.title);
    },
  );

  it('emits click event when button is clicked', () => {
    createWrapper();

    findButton().vm.$emit('click');

    expect(wrapper.emitted('click')).toHaveLength(1);
  });
});
