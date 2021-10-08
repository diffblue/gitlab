import { shallowMount } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';
import PolicyEditorLayout from 'ee/threat_monitoring/components/policy_editor/policy_editor_layout.vue';
import {
  DEFAULT_SCAN_EXECUTION_POLICY,
  fromYaml,
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
  const policyEditorEmptyStateSvgPath = 'path/to/svg';
  const scanExecutionDocumentationPath = 'path/to/docs';

  const factory = ({ propsData = {}, provide = {} } = {}) => {
    wrapper = shallowMount(ScanExecutionPolicyEditor, {
      propsData: {
        assignedPolicyProject: DEFAULT_ASSIGNED_POLICY_PROJECT,
        ...propsData,
      },
      provide: {
        disableScanExecutionUpdate: false,
        policyEditorEmptyStateSvgPath,
        projectId: 1,
        projectPath: defaultProjectPath,
        scanExecutionDocumentationPath,
        ...provide,
      },
    });
  };

  const factoryWithExistingPolicy = () => {
    return factory({ propsData: { existingPolicy: mockDastScanExecutionObject, isEditing: true } });
  };

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findPolicyEditorLayout = () => wrapper.findComponent(PolicyEditorLayout);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
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
          name:
            action === SECURITY_POLICY_ACTIONS.APPEND
              ? fromYaml(yamlEditorValue).name
              : mockDastScanExecutionObject.name,
          projectPath: defaultProjectPath,
          yamlEditorValue,
        });
        await wrapper.vm.$nextTick();
        expect(visitUrl).toHaveBeenCalled();
        expect(visitUrl).toHaveBeenCalledWith('/tests/-/merge_requests/2');
      },
    );
  });

  describe('when a user is not an owner of the project', () => {
    it('displays the empty state with the appropriate properties', async () => {
      factory({ provide: { disableScanExecutionUpdate: true } });
      await wrapper.vm.$nextTick();
      expect(findEmptyState().props()).toMatchObject({
        primaryButtonLink: scanExecutionDocumentationPath,
        svgPath: policyEditorEmptyStateSvgPath,
      });
    });
  });
});
