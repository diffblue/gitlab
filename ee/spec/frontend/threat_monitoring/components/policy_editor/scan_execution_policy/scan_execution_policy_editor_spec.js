import { shallowMount } from '@vue/test-utils';
import PolicyEditorLayout from 'ee/threat_monitoring/components/policy_editor/policy_editor_layout.vue';
import {
  DEFAULT_SCAN_EXECUTION_POLICY,
  modifyPolicy,
  SECURITY_POLICY_ACTIONS,
} from 'ee/threat_monitoring/components/policy_editor/scan_execution_policy/lib';
import ScanExecutionPolicyEditor from 'ee/threat_monitoring/components/policy_editor/scan_execution_policy/scan_execution_policy_editor.vue';
import { DEFAULT_ASSIGNED_POLICY_PROJECT } from 'ee/threat_monitoring/constants';
import {
  mockDastScanExecutionManifest,
  mockDastScanExecutionObject,
} from 'ee_jest/threat_monitoring/mocks/mock_data';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility', () => ({
  joinPaths: jest.requireActual('~/lib/utils/url_utility').joinPaths,
  visitUrl: jest.fn().mockName('visitUrlMock'),
}));

jest.mock('ee/threat_monitoring/components/policy_editor/scan_execution_policy/lib', () => ({
  DEFAULT_SCAN_EXECUTION_POLICY: jest.requireActual(
    'ee/threat_monitoring/components/policy_editor/scan_execution_policy/lib',
  ).DEFAULT_SCAN_EXECUTION_POLICY,
  fromYaml: jest.requireActual(
    'ee/threat_monitoring/components/policy_editor/scan_execution_policy/lib',
  ).fromYaml,
  toYaml: jest.requireActual(
    'ee/threat_monitoring/components/policy_editor/scan_execution_policy/lib',
  ).toYaml,
  SECURITY_POLICY_ACTIONS: jest.requireActual(
    'ee/threat_monitoring/components/policy_editor/scan_execution_policy/lib',
  ).SECURITY_POLICY_ACTIONS,
  modifyPolicy: jest.fn().mockResolvedValue({
    mergeRequest: { id: '2' },
    policyProject: { fullPath: 'tests' },
  }),
}));

describe('ScanExecutionPolicyEditor', () => {
  let wrapper;
  const defaultProjectPath = 'path/to/project';

  const factory = ({ propsData = {} } = {}) => {
    wrapper = shallowMount(ScanExecutionPolicyEditor, {
      propsData: {
        assignedPolicyProject: DEFAULT_ASSIGNED_POLICY_PROJECT,
        ...propsData,
      },
      provide: {
        disableScanExecutionUpdate: false,
        projectId: 1,
        projectPath: defaultProjectPath,
      },
    });
  };

  const factoryWithExistingPolicy = () => {
    return factory({ propsData: { existingPolicy: mockDastScanExecutionObject, isEditing: true } });
  };

  const findPolicyEditorLayout = () => wrapper.findComponent(PolicyEditorLayout);

  afterEach(() => {
    wrapper.destroy();
  });

  it('updates the policy yaml when "update-yaml" is emitted', async () => {
    factory();
    await wrapper.vm.$nextTick();
    const newManifest = 'new yaml!';
    expect(findPolicyEditorLayout().attributes('yamleditorvalue')).toBe(
      DEFAULT_SCAN_EXECUTION_POLICY,
    );
    await findPolicyEditorLayout().vm.$emit('update-yaml', newManifest);
    expect(findPolicyEditorLayout().attributes('yamleditorvalue')).toBe(newManifest);
  });

  it.each`
    status                            | action                             | event              | factoryFn                    | yamlEditorValue
    ${'to save a new policy'}         | ${SECURITY_POLICY_ACTIONS.APPEND}  | ${'save-policy'}   | ${factory}                   | ${DEFAULT_SCAN_EXECUTION_POLICY}
    ${'to update an existing policy'} | ${SECURITY_POLICY_ACTIONS.REPLACE} | ${'save-policy'}   | ${factoryWithExistingPolicy} | ${mockDastScanExecutionManifest}
    ${'to delete an existing policy'} | ${SECURITY_POLICY_ACTIONS.REMOVE}  | ${'remove-policy'} | ${factoryWithExistingPolicy} | ${mockDastScanExecutionManifest}
  `(
    'navigates to the new merge request when "modifyPolicy" is emitted $status',
    async ({ action, event, factoryFn, yamlEditorValue }) => {
      factoryFn();
      await wrapper.vm.$nextTick();
      findPolicyEditorLayout().vm.$emit(event);
      await wrapper.vm.$nextTick();
      expect(modifyPolicy).toHaveBeenCalledTimes(1);
      expect(modifyPolicy).toHaveBeenCalledWith({
        action,
        assignedPolicyProject: DEFAULT_ASSIGNED_POLICY_PROJECT,
        projectPath: defaultProjectPath,
        yamlEditorValue,
      });
      await wrapper.vm.$nextTick();
      expect(visitUrl).toHaveBeenCalled();
      expect(visitUrl).toHaveBeenCalledWith('/tests/-/merge_requests/2');
    },
  );
});
