import { GlAlert, GlFormSelect } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { POLICY_TYPE_COMPONENT_OPTIONS } from 'ee/threat_monitoring/components/constants';
import PolicyEditor from 'ee/threat_monitoring/components/policy_editor/policy_editor.vue';
import ScanExecutionPolicyEditor from 'ee/threat_monitoring/components/policy_editor/scan_execution_policy/scan_execution_policy_editor.vue';
import ScanResultPolicyEditor from 'ee/threat_monitoring/components/policy_editor/scan_result_policy/scan_result_policy_editor.vue';
import { DEFAULT_ASSIGNED_POLICY_PROJECT } from 'ee/threat_monitoring/constants';
import { mockDastScanExecutionObject, mockScanResultObject } from '../../mocks/mock_data';

describe('PolicyEditor component', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findFormSelect = () => wrapper.findComponent(GlFormSelect);
  const findScanExecutionPolicyEditor = () => wrapper.findComponent(ScanExecutionPolicyEditor);
  const findScanResultPolicyEditor = () => wrapper.findComponent(ScanResultPolicyEditor);

  const factory = ({ provide = {} } = {}) => {
    wrapper = shallowMount(PolicyEditor, {
      provide: {
        assignedPolicyProject: DEFAULT_ASSIGNED_POLICY_PROJECT,
        policyType: undefined,
        ...provide,
      },
      stubs: { GlFormSelect },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    beforeEach(factory);

    it('does not display the alert', () => {
      expect(findAlert().exists()).toBe(false);
    });

    it('renders the scan execution policy editor component', () => {
      expect(findScanExecutionPolicyEditor().props('existingPolicy')).toBe(null);
    });

    it('renders the form select', () => {
      const formSelect = findFormSelect();
      expect(formSelect.vm.$attrs.disabled).toBe(false);
      expect(formSelect.vm.$attrs).toEqual(
        expect.objectContaining({
          options: [
            POLICY_TYPE_COMPONENT_OPTIONS.scanExecution,
            POLICY_TYPE_COMPONENT_OPTIONS.scanResult,
          ],
          value: POLICY_TYPE_COMPONENT_OPTIONS.scanExecution.value,
        }),
      );
    });

    it('shows an alert when "error" is emitted from the component', async () => {
      const errorMessage = 'test';
      findScanExecutionPolicyEditor().vm.$emit('error', errorMessage);
      await nextTick();
      const alert = findAlert();
      expect(alert.exists()).toBe(true);
      expect(alert.props('title')).toBe(errorMessage);
    });

    it('shows an alert with details when multiline "error" is emitted from the component', async () => {
      const errorMessages = 'title\ndetail1';
      findScanExecutionPolicyEditor().vm.$emit('error', errorMessages);
      await nextTick();
      const alert = findAlert();
      expect(alert.exists()).toBe(true);
      expect(alert.props('title')).toBe('title');
      expect(alert.text()).toBe('detail1');
    });

    it.each`
      policyType         | option                                         | findComponent
      ${'scanExecution'} | ${POLICY_TYPE_COMPONENT_OPTIONS.scanExecution} | ${findScanExecutionPolicyEditor}
      ${'scanResult'}    | ${POLICY_TYPE_COMPONENT_OPTIONS.scanResult}    | ${findScanResultPolicyEditor}
    `(
      'renders the policy editor of type $policyType when selected',
      async ({ findComponent, option, policyType }) => {
        const formSelect = findFormSelect();
        formSelect.vm.$emit('change', policyType);
        await nextTick();
        const component = findComponent();
        expect(formSelect.attributes('value')).toBe(option.value);
        expect(component.exists()).toBe(true);
        expect(component.props('isEditing')).toBe(false);
      },
    );
  });

  describe('when an existing policy is present', () => {
    it.each`
      policyType                 | option                                         | existingPolicy                 | findComponent
      ${'scan_execution_policy'} | ${POLICY_TYPE_COMPONENT_OPTIONS.scanExecution} | ${mockDastScanExecutionObject} | ${findScanExecutionPolicyEditor}
      ${'scan_result_policy'}    | ${POLICY_TYPE_COMPONENT_OPTIONS.scanResult}    | ${mockScanResultObject}        | ${findScanResultPolicyEditor}
    `(
      'renders the disabled form select for existing policy of type $policyType',
      async ({ existingPolicy, findComponent, option, policyType }) => {
        factory({
          provide: { policyType, existingPolicy },
        });
        await nextTick();
        const formSelect = findFormSelect();
        expect(formSelect.exists()).toBe(true);
        expect(formSelect.attributes('value')).toBe(option.value);
        expect(formSelect.attributes('disabled')).toBe('true');
        const component = findComponent();
        expect(component.exists()).toBe(true);
        expect(component.props('isEditing')).toBe(true);
      },
    );
  });
});
