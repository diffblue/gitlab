import { shallowMount } from '@vue/test-utils';
import PolicyEditorLayout from 'ee/threat_monitoring/components/policy_editor/policy_editor_layout.vue';
import {
  DEFAULT_SCAN_EXECUTION_POLICY,
  savePolicy,
} from 'ee/threat_monitoring/components/policy_editor/scan_execution_policy/lib';
import ScanExecutionPolicyEditor from 'ee/threat_monitoring/components/policy_editor/scan_execution_policy/scan_execution_policy_editor.vue';
import { DEFAULT_ASSIGNED_POLICY_PROJECT } from 'ee/threat_monitoring/constants';
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
  savePolicy: jest.fn().mockResolvedValue({
    currentAssignedPolicyProject: { fullPath: 'tests' },
    mergeRequest: { id: '2' },
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

  const findPolicyEditorLayout = () => wrapper.findComponent(PolicyEditorLayout);

  beforeEach(() => {
    factory();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('updates the policy yaml when "update-yaml" is emitted', async () => {
    const newManifest = 'new yaml!';
    expect(findPolicyEditorLayout().attributes('yamleditorvalue')).toBe(
      DEFAULT_SCAN_EXECUTION_POLICY,
    );
    await findPolicyEditorLayout().vm.$emit('update-yaml', newManifest);
    expect(findPolicyEditorLayout().attributes('yamleditorvalue')).toBe(newManifest);
  });

  it('saves the policy when "savePolicy" is emitted', async () => {
    findPolicyEditorLayout().vm.$emit('save-policy');
    await wrapper.vm.$nextTick();
    expect(savePolicy).toHaveBeenCalledTimes(1);
    expect(savePolicy).toHaveBeenCalledWith({
      assignedPolicyProject: DEFAULT_ASSIGNED_POLICY_PROJECT,
      projectPath: defaultProjectPath,
      yamlEditorValue: DEFAULT_SCAN_EXECUTION_POLICY,
    });
    await wrapper.vm.$nextTick();
    expect(visitUrl).toHaveBeenCalled();
    expect(visitUrl).toHaveBeenCalledWith('/tests/-/merge_requests/2');
  });
});
