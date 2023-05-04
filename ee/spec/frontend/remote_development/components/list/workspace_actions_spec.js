import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import WorkspaceActions from 'ee/remote_development/components/list/workspace_actions.vue';
import {
  WORKSPACE_STATES as ACTUAL,
  WORKSPACE_DESIRED_STATES as DESIRED,
} from 'ee/remote_development/constants';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

describe('ee/remote_development/components/list/workspace_actions', () => {
  let wrapper;

  const createWrapper = (props = {}) => {
    wrapper = shallowMount(WorkspaceActions, {
      propsData: {
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const findButtons = () => wrapper.findAllComponents(GlButton);
  const findButtonWithLabel = (label) =>
    findButtons().wrappers.find((x) => x.attributes('aria-label') === label);
  const findButtonsAsData = () =>
    findButtons().wrappers.map((button) => ({
      tooltip: getBinding(button.element.parentNode, 'gl-tooltip').value,
      ariaLabel: button.attributes('aria-label'),
      icon: button.props('icon'),
      disabled: button.props('disabled'),
      loading: button.props('loading'),
    }));

  const createButtonData = (tooltip, icon, loading = false) => ({
    tooltip,
    icon,
    ariaLabel: tooltip,
    disabled: loading,
    loading,
  });

  const RESTART_BUTTON = createButtonData('Restart', 'retry');
  const RESTARTING_BUTTON = createButtonData('Restarting', 'retry', true);
  const START_BUTTON = createButtonData('Start', 'play');
  const STARTING_BUTTON = createButtonData('Starting', 'play', true);
  const STOP_BUTTON = createButtonData('Stop', 'stop');
  const STOPPING_BUTTON = createButtonData('Stopping', 'stop', true);
  const TERMINATE_BUTTON = createButtonData('Terminate', 'remove');
  const TERMINATING_BUTTON = createButtonData('Terminating', 'remove', true);

  it.each`
    actualState                 | desiredState                | buttonsData
    ${ACTUAL.creationRequested} | ${DESIRED.running}          | ${[STARTING_BUTTON, TERMINATE_BUTTON]}
    ${ACTUAL.creationRequested} | ${DESIRED.stopped}          | ${[START_BUTTON, TERMINATE_BUTTON]}
    ${ACTUAL.creationRequested} | ${DESIRED.terminated}       | ${[TERMINATING_BUTTON]}
    ${ACTUAL.creationRequested} | ${DESIRED.restartRequested} | ${[TERMINATE_BUTTON]}
    ${ACTUAL.starting}          | ${DESIRED.running}          | ${[STARTING_BUTTON, TERMINATE_BUTTON]}
    ${ACTUAL.starting}          | ${DESIRED.stopped}          | ${[START_BUTTON, TERMINATE_BUTTON]}
    ${ACTUAL.starting}          | ${DESIRED.terminated}       | ${[TERMINATING_BUTTON]}
    ${ACTUAL.starting}          | ${DESIRED.restartRequested} | ${[TERMINATE_BUTTON]}
    ${ACTUAL.running}           | ${DESIRED.running}          | ${[RESTART_BUTTON, STOP_BUTTON, TERMINATE_BUTTON]}
    ${ACTUAL.running}           | ${DESIRED.stopped}          | ${[STOPPING_BUTTON, TERMINATE_BUTTON]}
    ${ACTUAL.running}           | ${DESIRED.terminated}       | ${[TERMINATING_BUTTON]}
    ${ACTUAL.running}           | ${DESIRED.restartRequested} | ${[RESTARTING_BUTTON, TERMINATE_BUTTON]}
    ${ACTUAL.stopping}          | ${DESIRED.running}          | ${[STOP_BUTTON, TERMINATE_BUTTON]}
    ${ACTUAL.stopping}          | ${DESIRED.stopped}          | ${[STOPPING_BUTTON, TERMINATE_BUTTON]}
    ${ACTUAL.stopping}          | ${DESIRED.terminated}       | ${[TERMINATING_BUTTON]}
    ${ACTUAL.stopping}          | ${DESIRED.restartRequested} | ${[TERMINATE_BUTTON]}
    ${ACTUAL.stopped}           | ${DESIRED.running}          | ${[STARTING_BUTTON, TERMINATE_BUTTON]}
    ${ACTUAL.stopped}           | ${DESIRED.stopped}          | ${[RESTART_BUTTON, START_BUTTON, TERMINATE_BUTTON]}
    ${ACTUAL.stopped}           | ${DESIRED.terminated}       | ${[TERMINATING_BUTTON]}
    ${ACTUAL.stopped}           | ${DESIRED.restartRequested} | ${[RESTARTING_BUTTON, TERMINATE_BUTTON]}
    ${ACTUAL.terminated}        | ${DESIRED.running}          | ${[]}
    ${ACTUAL.terminated}        | ${DESIRED.stopped}          | ${[]}
    ${ACTUAL.terminated}        | ${DESIRED.terminated}       | ${[]}
    ${ACTUAL.terminated}        | ${DESIRED.restartRequested} | ${[]}
    ${ACTUAL.failed}            | ${DESIRED.running}          | ${[RESTART_BUTTON, STOP_BUTTON, TERMINATE_BUTTON]}
    ${ACTUAL.failed}            | ${DESIRED.stopped}          | ${[STOPPING_BUTTON, TERMINATE_BUTTON]}
    ${ACTUAL.failed}            | ${DESIRED.terminated}       | ${[TERMINATING_BUTTON]}
    ${ACTUAL.failed}            | ${DESIRED.restartRequested} | ${[RESTARTING_BUTTON, TERMINATE_BUTTON]}
    ${ACTUAL.error}             | ${DESIRED.running}          | ${[TERMINATE_BUTTON]}
    ${ACTUAL.error}             | ${DESIRED.stopped}          | ${[TERMINATE_BUTTON]}
    ${ACTUAL.error}             | ${DESIRED.terminated}       | ${[TERMINATING_BUTTON]}
    ${ACTUAL.error}             | ${DESIRED.restartRequested} | ${[TERMINATE_BUTTON]}
    ${ACTUAL.unknown}           | ${DESIRED.running}          | ${[]}
    ${ACTUAL.unknown}           | ${DESIRED.stopped}          | ${[]}
    ${ACTUAL.unknown}           | ${DESIRED.terminated}       | ${[]}
    ${ACTUAL.unknown}           | ${DESIRED.restartRequested} | ${[]}
    ${ACTUAL.terminating}       | ${DESIRED.running}          | ${[TERMINATE_BUTTON]}
    ${ACTUAL.terminating}       | ${DESIRED.stopped}          | ${[TERMINATE_BUTTON]}
    ${ACTUAL.terminating}       | ${DESIRED.terminated}       | ${[TERMINATING_BUTTON]}
    ${ACTUAL.terminating}       | ${DESIRED.restartRequested} | ${[TERMINATE_BUTTON]}
  `(
    'renders buttons - with actualState=$actualState and desiredState=$desiredState',
    ({ actualState, desiredState, buttonsData }) => {
      createWrapper({ actualState, desiredState });

      expect(findButtonsAsData()).toEqual(buttonsData);
    },
  );

  describe('with multiple buttons', () => {
    beforeEach(() => {
      createWrapper({ actualState: 'Stopped', desiredState: 'Stopped' });
    });

    it('does not apply margin class to first element', () => {
      const buttonMarginClasses = findButtons().wrappers.map((x) =>
        x.element.parentNode.classList.contains('gl-ml-2') ? 'gl-ml-2' : '',
      );

      expect(buttonMarginClasses).toEqual(['', 'gl-ml-2', 'gl-ml-2']);
    });
  });

  it.each`
    actualState                 | desiredState       | buttonLabel    | actionDesiredState
    ${ACTUAL.creationRequested} | ${DESIRED.running} | ${'Terminate'} | ${'Terminated'}
    ${ACTUAL.stopped}           | ${DESIRED.stopped} | ${'Start'}     | ${'Running'}
    ${ACTUAL.stopped}           | ${DESIRED.stopped} | ${'Restart'}   | ${'RestartRequested'}
    ${ACTUAL.running}           | ${DESIRED.running} | ${'Stop'}      | ${'Stopped'}
  `(
    'when clicking "$buttonLabel", emits "click" with "$actionDesiredState"',
    ({ actualState, desiredState, buttonLabel, actionDesiredState }) => {
      createWrapper({ actualState, desiredState });

      expect(wrapper.emitted('click')).toBeUndefined();

      const button = findButtonWithLabel(buttonLabel);

      button.vm.$emit('click');

      expect(wrapper.emitted('click')).toEqual([[actionDesiredState]]);
    },
  );
});
