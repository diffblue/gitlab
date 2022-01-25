import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import PolicyAlertPicker from 'ee/threat_monitoring/components/policy_editor/policy_alert_picker.vue';
import getAgentCount from 'ee/threat_monitoring/graphql/queries/get_agent_count.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

Vue.use(VueApollo);

describe('PolicyAlertPicker component', () => {
  let wrapper;

  const createMockApolloProvider = ({ agentCount }) => {
    const getAgentCountHandler = jest
      .fn()
      .mockResolvedValue({ data: { project: { id: '1', clusterAgents: { count: agentCount } } } });

    return createMockApollo([[getAgentCount, getAgentCountHandler]]);
  };

  const defaultProps = { policyAlert: false };

  const findAddAlertButton = () => wrapper.findByTestId('add-alert');
  const findAlertMessage = () => wrapper.findByTestId('policy-alert-message');
  const findHighVolumeAlert = () => wrapper.findByTestId('policy-alert-high-volume');
  const findNoAgentAlert = () => wrapper.findByTestId('policy-alert-no-agent');
  const findRemoveAlertButton = () => wrapper.findByTestId('remove-alert');

  const createWrapper = async ({ propsData = defaultProps, agentCount = 1 } = {}) => {
    const apolloProvider = createMockApolloProvider({ agentCount });

    wrapper = extendedWrapper(
      shallowMount(PolicyAlertPicker, {
        apolloProvider,
        propsData: {
          ...propsData,
        },
        provide: {
          createAgentHelpPath: '',
          projectPath: '',
        },
      }),
    );
    await nextTick();
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('loading', () => {
    describe('default state', () => {
      beforeEach(async () => {
        createWrapper();
      });

      it('does render the enabled add alert button ', () => {
        expect(findAddAlertButton().exists()).toBe(true);
        expect(findAddAlertButton().props('disabled')).toBe(false);
      });

      it('does not render the "no agent" alert', () => {
        expect(findNoAgentAlert().exists()).toBe(false);
      });
    });

    describe('alert enabled', () => {
      beforeEach(async () => {
        createWrapper({ propsData: { policyAlert: true } });
      });

      it('does render the "high volume" alert', () => {
        expect(findHighVolumeAlert().exists()).toBe(true);
      });

      it('does not render the "no agent" alert', () => {
        expect(findNoAgentAlert().exists()).toBe(false);
      });
    });
  });

  describe('default state', () => {
    describe('agent installed', () => {
      beforeEach(async () => {
        await createWrapper();
      });

      it('does render the enabled add alert button ', () => {
        expect(findAddAlertButton().exists()).toBe(true);
        expect(findAddAlertButton().props('disabled')).toBe(false);
      });

      it('does not render the "high volume" alert', () => {
        expect(findHighVolumeAlert().exists()).toBe(false);
      });

      it('does not render the alert message', () => {
        expect(findAlertMessage().exists()).toBe(false);
      });

      it('does not render the remove alert button', () => {
        expect(findRemoveAlertButton().exists()).toBe(false);
      });

      it('does not render the "no agent" alert when there is an agent, ', () => {
        expect(findNoAgentAlert().exists()).toBe(false);
      });

      it('does emit an event to add the alert', () => {
        findAddAlertButton().vm.$emit('click');
        expect(wrapper.emitted('update-alert')).toEqual([[true]]);
      });
    });

    describe('no agent installed', () => {
      beforeEach(async () => {
        await createWrapper({ agentCount: 0 });
      });

      it('does render the "no agent" alert', () => {
        expect(findNoAgentAlert().exists()).toBe(true);
      });

      it('does render the disabled add alert button ', async () => {
        expect(findAddAlertButton().exists()).toBe(true);
        expect(findAddAlertButton().props('disabled')).toBe(true);
      });
    });
  });

  describe('alert enabled', () => {
    describe('agent installed', () => {
      beforeEach(async () => {
        await createWrapper({ propsData: { policyAlert: true } });
      });

      it('does not render the add alert button', () => {
        expect(findAddAlertButton().exists()).toBe(false);
      });

      it('does render the "high volume" alert', () => {
        expect(findHighVolumeAlert().exists()).toBe(true);
      });

      it('does render the alert message', () => {
        expect(findAlertMessage().exists()).toBe(true);
      });

      it('does render the remove alert button', () => {
        expect(findRemoveAlertButton().exists()).toBe(true);
      });

      it('does not render the "no agent" alert', () => {
        expect(findNoAgentAlert().exists()).toBe(false);
      });

      it('does emit an event to remove the alert', () => {
        findRemoveAlertButton().vm.$emit('click');
        expect(wrapper.emitted('update-alert')).toEqual([[false]]);
      });
    });

    describe('no agent installed', () => {
      beforeEach(async () => {
        await createWrapper({ propsData: { policyAlert: true }, agentCount: 0 });
      });
      it('does render the "no agent" alert', () => {
        expect(findNoAgentAlert().exists()).toBe(true);
      });

      it('does not render the "high volume" alert', async () => {
        expect(findHighVolumeAlert().exists()).toBe(false);
      });
    });
  });
});
