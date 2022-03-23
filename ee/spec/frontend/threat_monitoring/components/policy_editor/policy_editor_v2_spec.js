import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { POLICY_TYPE_COMPONENT_OPTIONS } from 'ee/threat_monitoring/components/constants';
import EnvironmentPicker from 'ee/threat_monitoring/components/environment_picker.vue';
import NetworkPolicyEditor from 'ee/threat_monitoring/components/policy_editor/network_policy/network_policy_editor.vue';
import PolicyEditor from 'ee/threat_monitoring/components/policy_editor/policy_editor_v2.vue';
import ScanExecutionPolicyEditor from 'ee/threat_monitoring/components/policy_editor/scan_execution_policy/scan_execution_policy_editor.vue';
import ScanResultPolicyEditor from 'ee/threat_monitoring/components/policy_editor/scan_result_policy/scan_result_policy_editor.vue';
import { DEFAULT_ASSIGNED_POLICY_PROJECT } from 'ee/threat_monitoring/constants';

describe('PolicyEditor V2 component', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findEnvironmentPicker = () => wrapper.findComponent(EnvironmentPicker);
  const findNetworkPolicyEditor = () => wrapper.findComponent(NetworkPolicyEditor);
  const findScanExecutionPolicyEditor = () => wrapper.findComponent(ScanExecutionPolicyEditor);
  const findScanResultPolicyEditor = () => wrapper.findComponent(ScanResultPolicyEditor);

  const factory = ({ propsData = {}, provide = {} } = {}) => {
    wrapper = shallowMount(PolicyEditor, {
      propsData: {
        assignedPolicyProject: DEFAULT_ASSIGNED_POLICY_PROJECT,
        selectedPolicyType: 'container',
        ...propsData,
      },
      provide: {
        policyType: undefined,
        ...provide,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    beforeEach(factory);

    it.each`
      component               | status                | findComponent            | state
      ${'environment picker'} | ${'does display'}     | ${findEnvironmentPicker} | ${true}
      ${'alert'}              | ${'does not display'} | ${findAlert}             | ${false}
    `('$status the $component', ({ findComponent, state }) => {
      expect(findComponent().exists()).toBe(state);
    });

    it('renders the network policy editor component', () => {
      expect(findNetworkPolicyEditor().props('existingPolicy')).toBe(null);
    });

    it('shows an alert when "error" is emitted from the component', async () => {
      const errorMessage = 'test';
      findNetworkPolicyEditor().vm.$emit('error', errorMessage);
      await nextTick();
      const alert = findAlert();
      expect(alert.exists()).toBe(true);
      expect(alert.props('title')).toBe(errorMessage);
    });

    it('shows an alert with details when multiline "error" is emitted from the component', async () => {
      const errorMessages = 'title\ndetail1';
      findNetworkPolicyEditor().vm.$emit('error', errorMessages);
      await nextTick();
      const alert = findAlert();
      expect(alert.exists()).toBe(true);
      expect(alert.props('title')).toBe('title');
      expect(alert.text()).toBe('detail1');
    });

    it.each`
      policyTypeId                                         | findComponent
      ${POLICY_TYPE_COMPONENT_OPTIONS.container.value}     | ${findNetworkPolicyEditor}
      ${POLICY_TYPE_COMPONENT_OPTIONS.scanExecution.value} | ${findScanExecutionPolicyEditor}
      ${POLICY_TYPE_COMPONENT_OPTIONS.scanResult.value}    | ${findScanResultPolicyEditor}
    `(
      'renders the policy editor of type $policyType when selected',
      async ({ findComponent, policyTypeId }) => {
        wrapper.setProps({ selectedPolicyType: policyTypeId });
        await nextTick();
        const component = findComponent();
        expect(component.exists()).toBe(true);
        expect(component.props('isEditing')).toBe(false);
      },
    );
  });
});
