import { shallowMount } from '@vue/test-utils';
import { GlEmptyState, GlAlert, GlFormInput, GlFormTextarea, GlToggle } from '@gitlab/ui';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import PolicyEditorLayout from 'ee/threat_monitoring/components/policy_editor/policy_editor_layout.vue';
import {
  DEFAULT_SCAN_RESULT_POLICY,
  fromYaml,
} from 'ee/threat_monitoring/components/policy_editor/scan_result_policy/lib';
import ScanResultPolicyEditor from 'ee/threat_monitoring/components/policy_editor/scan_result_policy/scan_result_policy_editor.vue';
import { DEFAULT_ASSIGNED_POLICY_PROJECT } from 'ee/threat_monitoring/constants';
import {
  mockScanResultManifest,
  mockScanResultObject,
} from 'ee_jest/threat_monitoring/mocks/mock_data';
import { visitUrl } from '~/lib/utils/url_utility';

import { modifyPolicy } from 'ee/threat_monitoring/components/policy_editor/utils';
import {
  SECURITY_POLICY_ACTIONS,
  EDITOR_MODE_YAML,
} from 'ee/threat_monitoring/components/policy_editor/constants';
import DimDisableContainer from 'ee/threat_monitoring/components/policy_editor/dim_disable_container.vue';
import PolicyActionBuilder from 'ee/threat_monitoring/components/policy_editor/scan_result_policy/policy_action_builder.vue';
import PolicyRuleBuilder from 'ee/threat_monitoring/components/policy_editor/scan_result_policy/policy_rule_builder.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  joinPaths: jest.requireActual('~/lib/utils/url_utility').joinPaths,
  visitUrl: jest.fn().mockName('visitUrlMock'),
  setUrlFragment: jest.requireActual('~/lib/utils/url_utility').setUrlFragment,
}));

const newlyCreatedPolicyProject = {
  branch: 'main',
  fullPath: 'path/to/new-project',
};
jest.mock('ee/threat_monitoring/components/policy_editor/utils', () => ({
  assignSecurityPolicyProject: jest.fn().mockResolvedValue({
    branch: 'main',
    fullPath: 'path/to/new-project',
  }),
  modifyPolicy: jest.fn().mockResolvedValue({ id: '2' }),
}));

describe('ScanResultPolicyEditor', () => {
  let wrapper;
  const defaultProjectPath = 'path/to/project';
  const policyEditorEmptyStateSvgPath = 'path/to/svg';
  const scanPolicyDocumentationPath = 'path/to/docs';
  const assignedPolicyProject = {
    branch: 'main',
    fullPath: 'path/to/existing-project',
  };
  const scanResultPolicyApprovers = [{ id: 1, username: 'username', state: 'active' }];

  const factory = ({ propsData = {}, provide = {} } = {}) => {
    wrapper = shallowMount(ScanResultPolicyEditor, {
      propsData: {
        assignedPolicyProject: DEFAULT_ASSIGNED_POLICY_PROJECT,
        ...propsData,
      },
      provide: {
        disableScanPolicyUpdate: false,
        policyEditorEmptyStateSvgPath,
        projectId: 1,
        projectPath: defaultProjectPath,
        scanPolicyDocumentationPath,
        scanResultPolicyApprovers,
        ...provide,
      },
    });
    nextTick();
  };

  const factoryWithExistingPolicy = () => {
    return factory({
      propsData: {
        assignedPolicyProject,
        existingPolicy: mockScanResultObject,
        isEditing: true,
      },
    });
  };

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findPolicyEditorLayout = () => wrapper.findComponent(PolicyEditorLayout);
  const findPolicyActionBuilder = () => wrapper.findComponent(PolicyActionBuilder);
  const findAllPolicyActionBuilders = () => wrapper.findAllComponents(PolicyActionBuilder);
  const findAddRuleButton = () => wrapper.find('[data-testid="add-rule"]');
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findNameInput = () => wrapper.findComponent(GlFormInput);
  const findDescriptionTextArea = () => wrapper.findComponent(GlFormTextarea);
  const findEnableToggle = () => wrapper.findComponent(GlToggle);
  const findAllDisabledComponents = () => wrapper.findAllComponents(DimDisableContainer);
  const findYamlPreview = () => wrapper.find('[data-testid="yaml-preview"]');
  const findAllRuleBuilders = () => wrapper.findAllComponents(PolicyRuleBuilder);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    it('updates the policy yaml when "update-yaml" is emitted', async () => {
      const newManifest = 'new yaml!';
      await factory();

      expect(findPolicyEditorLayout().attributes('yamleditorvalue')).toBe(
        DEFAULT_SCAN_RESULT_POLICY,
      );

      await findPolicyEditorLayout().vm.$emit('update-yaml', newManifest);

      expect(findPolicyEditorLayout().attributes('yamleditorvalue')).toBe(newManifest);
    });

    it('displays the inital rule and add rule button', async () => {
      await factory();

      expect(findAllRuleBuilders().length).toBe(1);
      expect(findAddRuleButton().exists()).toBe(true);
    });

    it('displays alert for invalid yaml', async () => {
      await factory();

      expect(findAlert().exists()).toBe(false);

      await findPolicyEditorLayout().vm.$emit('update-yaml', 'invalid manifest');

      expect(findAlert().exists()).toBe(true);
    });

    it('disables all rule mode related components when the yaml is invalid', async () => {
      await factory();

      await findPolicyEditorLayout().vm.$emit('update-yaml', 'invalid manifest');

      expect(findNameInput().attributes('disabled')).toBe('true');
      expect(findDescriptionTextArea().attributes('disabled')).toBe('true');
      expect(findEnableToggle().props('disabled')).toBe(true);
      expect(findAllDisabledComponents().at(0).props('disabled')).toBe(true);
      expect(findAllDisabledComponents().at(1).props('disabled')).toBe(true);
    });

    it('defaults to YAML mode', async () => {
      await factory();

      expect(findPolicyEditorLayout().attributes().defaulteditormode).toBe(EDITOR_MODE_YAML);
    });

    describe.each`
      currentComponent           | newValue                    | event
      ${findNameInput}           | ${'new policy name'}        | ${'input'}
      ${findDescriptionTextArea} | ${'new policy description'} | ${'input'}
      ${findEnableToggle}        | ${true}                     | ${'change'}
    `('triggering a change on $currentComponent', ({ currentComponent, newValue, event }) => {
      it('updates YAML when switching modes', async () => {
        await factory();

        await currentComponent().vm.$emit(event, newValue);
        await findPolicyEditorLayout().vm.$emit('update-editor-mode', EDITOR_MODE_YAML);

        expect(findPolicyEditorLayout().attributes('yamleditorvalue')).toMatch(newValue.toString());
      });

      it('updates the yaml preview', async () => {
        await factory();

        await currentComponent().vm.$emit(event, newValue);

        expect(findYamlPreview().html()).toMatch(newValue.toString());
      });
    });

    it.each`
      status                            | action                             | event              | factoryFn                    | yamlEditorValue               | currentlyAssignedPolicyProject
      ${'to save a new policy'}         | ${SECURITY_POLICY_ACTIONS.APPEND}  | ${'save-policy'}   | ${factory}                   | ${DEFAULT_SCAN_RESULT_POLICY} | ${newlyCreatedPolicyProject}
      ${'to update an existing policy'} | ${SECURITY_POLICY_ACTIONS.REPLACE} | ${'save-policy'}   | ${factoryWithExistingPolicy} | ${mockScanResultManifest}     | ${assignedPolicyProject}
      ${'to delete an existing policy'} | ${SECURITY_POLICY_ACTIONS.REMOVE}  | ${'remove-policy'} | ${factoryWithExistingPolicy} | ${mockScanResultManifest}     | ${assignedPolicyProject}
    `(
      'navigates to the new merge request when "modifyPolicy" is emitted $status',
      async ({ action, event, factoryFn, yamlEditorValue, currentlyAssignedPolicyProject }) => {
        await factoryFn();

        findPolicyEditorLayout().vm.$emit(event);

        await waitForPromises();

        expect(modifyPolicy).toHaveBeenCalledWith({
          action,
          assignedPolicyProject: currentlyAssignedPolicyProject,
          name:
            action === SECURITY_POLICY_ACTIONS.APPEND
              ? fromYaml(yamlEditorValue).name
              : mockScanResultObject.name,
          projectPath: defaultProjectPath,
          yamlEditorValue,
        });
        expect(visitUrl).toHaveBeenCalledWith(
          `/${currentlyAssignedPolicyProject.fullPath}/-/merge_requests/2`,
        );
      },
    );

    it('adds a new rule', async () => {
      const rulesCount = 1;
      factory();
      await nextTick();

      expect(findAllRuleBuilders().length).toBe(rulesCount);

      await findAddRuleButton().vm.$emit('click');

      expect(findAllRuleBuilders()).toHaveLength(rulesCount + 1);
    });

    it('hides add button when the limit of five rules has been reached', async () => {
      const limit = 5;
      factory();
      await nextTick();
      await findAddRuleButton().vm.$emit('click');
      await findAddRuleButton().vm.$emit('click');
      await findAddRuleButton().vm.$emit('click');
      await findAddRuleButton().vm.$emit('click');

      expect(findAllRuleBuilders()).toHaveLength(limit);
      expect(findAddRuleButton().exists()).toBe(false);
    });

    it('updates an existing rule', async () => {
      const newValue = {
        type: 'scan_finding',
        branches: [],
        scanners: [],
        vulnerabilities_allowed: 1,
        severity_levels: [],
        vulnerability_states: [],
      };
      factory();
      await nextTick();
      await findAllRuleBuilders().at(0).vm.$emit('changed', newValue);

      expect(wrapper.vm.policy.rules[0]).toEqual(newValue);
      expect(findYamlPreview().html()).toMatch('vulnerabilities_allowed: 1');
    });

    it('deletes the initial rule', async () => {
      const initialRuleCount = 1;
      factory();
      await nextTick();

      expect(findAllRuleBuilders()).toHaveLength(initialRuleCount);

      await findAllRuleBuilders().at(0).vm.$emit('remove', 0);

      expect(findAllRuleBuilders()).toHaveLength(initialRuleCount - 1);
    });
  });

  describe('when a user is not an owner of the project', () => {
    it('displays the empty state with the appropriate properties', async () => {
      await factory({ provide: { disableScanPolicyUpdate: true } });

      const emptyState = findEmptyState();

      expect(emptyState.props('primaryButtonLink')).toMatch(scanPolicyDocumentationPath);
      expect(emptyState.props('primaryButtonLink')).toMatch('scan-result-policy-editor');
      expect(emptyState.props('svgPath')).toBe(policyEditorEmptyStateSvgPath);
    });
  });

  describe('with policy action builder', () => {
    it('renders a single policy action builder', async () => {
      factory();

      await nextTick();

      expect(findAllPolicyActionBuilders()).toHaveLength(1);
      expect(findPolicyActionBuilder().props('existingApprovers')).toEqual(
        scanResultPolicyApprovers,
      );
    });

    it('updates policy action when edited', async () => {
      const UPDATED_ACTION = { type: 'required_approval', group_approvers_ids: [1] };
      factory();

      await nextTick();
      await findPolicyActionBuilder().vm.$emit('changed', UPDATED_ACTION);

      expect(findPolicyActionBuilder().props('initAction')).toEqual(UPDATED_ACTION);
    });
  });
});
