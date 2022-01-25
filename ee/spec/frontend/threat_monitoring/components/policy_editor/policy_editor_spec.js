import { GlAlert, GlFormSelect } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { POLICY_TYPE_COMPONENT_OPTIONS } from 'ee/threat_monitoring/components/constants';
import EnvironmentPicker from 'ee/threat_monitoring/components/environment_picker.vue';
import NetworkPolicyEditor from 'ee/threat_monitoring/components/policy_editor/network_policy/network_policy_editor.vue';
import PolicyEditor from 'ee/threat_monitoring/components/policy_editor/policy_editor.vue';
import ScanExecutionPolicyEditor from 'ee/threat_monitoring/components/policy_editor/scan_execution_policy/scan_execution_policy_editor.vue';
import ScanResultPolicyEditor from 'ee/threat_monitoring/components/policy_editor/scan_result_policy/scan_result_policy_editor.vue';
import { DEFAULT_ASSIGNED_POLICY_PROJECT } from 'ee/threat_monitoring/constants';
import {
  mockDastScanExecutionObject,
  mockL3Manifest,
  mockScanResultObject,
} from '../../mocks/mock_data';

describe('PolicyEditor component', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findEnvironmentPicker = () => wrapper.findComponent(EnvironmentPicker);
  const findFormSelect = () => wrapper.findComponent(GlFormSelect);
  const findNeworkPolicyEditor = () => wrapper.findComponent(NetworkPolicyEditor);
  const findScanExecutionPolicyEditor = () => wrapper.findComponent(ScanExecutionPolicyEditor);
  const findScanResultPolicyEditor = () => wrapper.findComponent(ScanResultPolicyEditor);

  const factory = ({ propsData = {}, provide = {} } = {}) => {
    wrapper = shallowMount(PolicyEditor, {
      propsData: {
        assignedPolicyProject: DEFAULT_ASSIGNED_POLICY_PROJECT,
        ...propsData,
      },
      provide: {
        policyType: undefined,
        glFeatures: { scanResultPolicy: true },
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

    it.each`
      component               | status                | findComponent            | state
      ${'environment picker'} | ${'does display'}     | ${findEnvironmentPicker} | ${true}
      ${'alert'}              | ${'does not display'} | ${findAlert}             | ${false}
    `('$status the $component', ({ findComponent, state }) => {
      expect(findComponent().exists()).toBe(state);
    });

    it('renders the network policy editor component', () => {
      expect(findNeworkPolicyEditor().props('existingPolicy')).toBe(null);
    });

    it('renders the form select', () => {
      const formSelect = findFormSelect();
      expect(formSelect.attributes('value')).toBe(POLICY_TYPE_COMPONENT_OPTIONS.container.value);
      expect(formSelect.attributes('disabled')).toBe(undefined);
    });

    it('shows an alert when "error" is emitted from the component', async () => {
      const errorMessage = 'test';
      findNeworkPolicyEditor().vm.$emit('error', errorMessage);
      await nextTick();
      const alert = findAlert();
      expect(alert.exists()).toBe(true);
      expect(alert.text()).toBe(errorMessage);
    });

    it.each`
      policyType         | option                                         | findComponent
      ${'container'}     | ${POLICY_TYPE_COMPONENT_OPTIONS.container}     | ${findNeworkPolicyEditor}
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

    describe('with scan_result_policy feature flag disabled', () => {
      beforeEach(async () => {
        factory({ provide: { glFeatures: { scanResultPolicy: false } } });
        const formSelect = findFormSelect();
        formSelect.vm.$emit('change', POLICY_TYPE_COMPONENT_OPTIONS.scanResult.value);
        await nextTick();
      });

      it('does not render scan result policy', () => {
        const component = findScanResultPolicyEditor();
        expect(component.exists()).toBe(false);
      });

      it('renders network policy with isEditing set to false', () => {
        const component = findNeworkPolicyEditor();
        expect(component.exists()).toBe(true);
        expect(component.props('isEditing')).toBe(false);
      });
    });
  });

  describe('when an existing policy is present', () => {
    it.each`
      policyType                 | option                                         | existingPolicy                                                              | findComponent
      ${'container_policy'}      | ${POLICY_TYPE_COMPONENT_OPTIONS.container}     | ${{ manifest: mockL3Manifest, creation_timestamp: '2020-04-14T00:08:30Z' }} | ${findNeworkPolicyEditor}
      ${'scan_execution_policy'} | ${POLICY_TYPE_COMPONENT_OPTIONS.scanExecution} | ${mockDastScanExecutionObject}                                              | ${findScanExecutionPolicyEditor}
      ${'scan_result_policy'}    | ${POLICY_TYPE_COMPONENT_OPTIONS.scanResult}    | ${mockScanResultObject}                                                     | ${findScanResultPolicyEditor}
    `(
      'renders the disabled form select for existing policy of type $policyType',
      async ({ existingPolicy, findComponent, option, policyType }) => {
        factory({
          propsData: { existingPolicy },
          provide: { policyType, glFeatures: { scanResultPolicy: true } },
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

    describe('with scan_result_policy feature flag disabled', () => {
      beforeEach(() => {
        factory({
          propsData: { existingPolicy: mockScanResultObject },
          provide: {
            policyType: POLICY_TYPE_COMPONENT_OPTIONS.scanResult.urlParameter,
            glFeatures: { scanResultPolicy: false },
          },
        });
      });

      it('does not display the scan result as one of the dropdown options', () => {
        const formSelect = findFormSelect();
        expect(formSelect.vm.$attrs.options).toMatchObject([
          POLICY_TYPE_COMPONENT_OPTIONS.container,
          POLICY_TYPE_COMPONENT_OPTIONS.scanExecution,
        ]);
      });

      it('renders network policy with isEditing set to true', () => {
        const component = findNeworkPolicyEditor();
        expect(component.exists()).toBe(true);
        expect(component.props('isEditing')).toBe(true);
      });
    });
  });
});
