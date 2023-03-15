import { GlEmptyState } from '@gitlab/ui';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PolicyActionBuilder from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/policy_action_builder.vue';
import PolicyRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/policy_rule_builder.vue';
import PolicyEditorLayout from 'ee/security_orchestration/components/policy_editor/policy_editor_layout.vue';
import {
  DEFAULT_SCAN_EXECUTION_POLICY,
  buildScannerAction,
  fromYaml,
} from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/lib';
import ScanExecutionPolicyEditor from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/scan_execution_policy_editor.vue';
import { DEFAULT_ASSIGNED_POLICY_PROJECT } from 'ee/security_orchestration/constants';
import {
  mockDastScanExecutionManifest,
  mockDastScanExecutionObject,
} from 'ee_jest/security_orchestration/mocks/mock_scan_execution_policy_data';
import { visitUrl } from '~/lib/utils/url_utility';

import { modifyPolicy } from 'ee/security_orchestration/components/policy_editor/utils';
import {
  SECURITY_POLICY_ACTIONS,
  RUNNER_TAGS_PARSING_ERROR,
  DAST_SCANNERS_PARSING_ERROR,
} from 'ee/security_orchestration/components/policy_editor/constants';
import {
  DEFAULT_SCANNER,
  SCAN_EXECUTION_PIPELINE_RULE,
  POLICY_ACTION_BUILDER_TAGS_ERROR_KEY,
  POLICY_ACTION_BUILDER_DAST_PROFILES_ERROR_KEY,
} from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/constants';
import { RULE_KEY_MAP } from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/lib/rules';

jest.mock('~/lib/utils/url_utility', () => ({
  joinPaths: jest.requireActual('~/lib/utils/url_utility').joinPaths,
  visitUrl: jest.fn().mockName('visitUrlMock'),
  setUrlFragment: jest.requireActual('~/lib/utils/url_utility').setUrlFragment,
}));

const newlyCreatedPolicyProject = {
  branch: 'main',
  fullPath: 'path/to/new-project',
};

jest.mock('ee/security_orchestration/components/policy_editor/utils', () => ({
  assignSecurityPolicyProject: jest.fn().mockResolvedValue({
    branch: 'main',
    fullPath: 'path/to/new-project',
  }),
  hasInvalidCron: jest.requireActual('ee/security_orchestration/components/policy_editor/utils')
    .hasInvalidCron,
  modifyPolicy: jest.fn().mockResolvedValue({ id: '2' }),
  isValidPolicy: jest.requireActual('ee/security_orchestration/components/policy_editor/utils')
    .isValidPolicy,
}));

describe('ScanExecutionPolicyEditor', () => {
  let wrapper;
  const defaultProjectPath = 'path/to/project';
  const policyEditorEmptyStateSvgPath = 'path/to/svg';
  const scanPolicyDocumentationPath = 'path/to/docs';
  const assignedPolicyProject = {
    branch: 'main',
    fullPath: 'path/to/existing-project',
  };

  const factory = ({ propsData = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(ScanExecutionPolicyEditor, {
      propsData: {
        assignedPolicyProject: DEFAULT_ASSIGNED_POLICY_PROJECT,
        ...propsData,
      },
      provide: {
        disableScanPolicyUpdate: false,
        policyEditorEmptyStateSvgPath,
        namespacePath: defaultProjectPath,
        scanPolicyDocumentationPath,
        ...provide,
      },
    });
  };

  const factoryWithExistingPolicy = () => {
    return factory({
      propsData: {
        assignedPolicyProject,
        existingPolicy: mockDastScanExecutionObject,
        isEditing: true,
      },
    });
  };

  const findAddActionButton = () => wrapper.findByTestId('add-action');
  const findAddRuleButton = () => wrapper.findByTestId('add-rule');
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findPolicyEditorLayout = () => wrapper.findComponent(PolicyEditorLayout);
  const findPolicyActionBuilder = () => wrapper.findComponent(PolicyActionBuilder);
  const findAllPolicyActionBuilders = () => wrapper.findAllComponents(PolicyActionBuilder);
  const findPolicyRuleBuilder = () => wrapper.findComponent(PolicyRuleBuilder);
  const findAllPolicyRuleBuilders = () => wrapper.findAllComponents(PolicyRuleBuilder);

  describe('saving a policy', () => {
    it.each`
      status                            | action                             | event              | factoryFn                    | yamlEditorValue                  | currentlyAssignedPolicyProject
      ${'to save a new policy'}         | ${SECURITY_POLICY_ACTIONS.APPEND}  | ${'save-policy'}   | ${factory}                   | ${DEFAULT_SCAN_EXECUTION_POLICY} | ${newlyCreatedPolicyProject}
      ${'to update an existing policy'} | ${SECURITY_POLICY_ACTIONS.REPLACE} | ${'save-policy'}   | ${factoryWithExistingPolicy} | ${mockDastScanExecutionManifest} | ${assignedPolicyProject}
      ${'to delete an existing policy'} | ${SECURITY_POLICY_ACTIONS.REMOVE}  | ${'remove-policy'} | ${factoryWithExistingPolicy} | ${mockDastScanExecutionManifest} | ${assignedPolicyProject}
    `(
      'navigates to the new merge request when "modifyPolicy" is emitted $status',
      async ({ action, event, factoryFn, yamlEditorValue, currentlyAssignedPolicyProject }) => {
        factoryFn();
        await nextTick();
        findPolicyEditorLayout().vm.$emit(event);
        await waitForPromises();
        expect(modifyPolicy).toHaveBeenCalledTimes(1);
        expect(modifyPolicy).toHaveBeenCalledWith({
          action,
          assignedPolicyProject: currentlyAssignedPolicyProject,
          name:
            action === SECURITY_POLICY_ACTIONS.APPEND
              ? fromYaml({ manifest: yamlEditorValue }).name
              : mockDastScanExecutionObject.name,
          namespacePath: defaultProjectPath,
          yamlEditorValue,
        });
        await nextTick();
        expect(visitUrl).toHaveBeenCalled();
        expect(visitUrl).toHaveBeenCalledWith(
          `/${currentlyAssignedPolicyProject.fullPath}/-/merge_requests/2`,
        );
      },
    );
  });

  describe('when a user is not an owner of the project', () => {
    it('displays the empty state with the appropriate properties', async () => {
      factory({ provide: { disableScanPolicyUpdate: true } });
      await nextTick();
      const emptyState = findEmptyState();

      expect(emptyState.props('primaryButtonLink')).toMatch(scanPolicyDocumentationPath);
      expect(emptyState.props('primaryButtonLink')).toMatch('scan-execution-policy-editor');
      expect(emptyState.props('svgPath')).toBe(policyEditorEmptyStateSvgPath);
    });
  });

  describe('modifying a policy', () => {
    beforeEach(factory);

    it('updates the yaml and policy object when "update-yaml" is emitted', async () => {
      const newManifest = `name: test
enabled: true`;

      expect(findPolicyEditorLayout().props('yamlEditorValue')).toBe(DEFAULT_SCAN_EXECUTION_POLICY);
      expect(findPolicyEditorLayout().props('policy')).toMatchObject(
        fromYaml({ manifest: DEFAULT_SCAN_EXECUTION_POLICY }),
      );
      findPolicyEditorLayout().vm.$emit('update-yaml', newManifest);
      await nextTick();
      expect(findPolicyEditorLayout().props('yamlEditorValue')).toBe(newManifest);
      expect(findPolicyEditorLayout().props('policy')).toMatchObject({ enabled: true });
    });

    it.each`
      component        | oldValue | newValue
      ${'name'}        | ${''}    | ${'new policy name'}
      ${'description'} | ${''}    | ${'new description'}
      ${'enabled'}     | ${true}  | ${false}
    `('triggers a change on $component', async ({ component, newValue, oldValue }) => {
      expect(findPolicyEditorLayout().props('policy')[component]).toBe(oldValue);
      expect(findPolicyEditorLayout().props('yamlEditorValue')).toMatch(
        `${component}: ${oldValue}`,
      );

      findPolicyEditorLayout().vm.$emit('set-policy-property', component, newValue);
      await nextTick();

      expect(findPolicyEditorLayout().props('policy')[component]).toBe(newValue);
      expect(findPolicyEditorLayout().props('yamlEditorValue')).toMatch(
        `${component}: ${newValue}`,
      );
    });
  });

  describe('policy rule builder', () => {
    beforeEach(factory);

    it('should add new rule', async () => {
      const initialValue = [RULE_KEY_MAP[SCAN_EXECUTION_PIPELINE_RULE]()];
      expect(findPolicyEditorLayout().props('policy').rules).toStrictEqual(initialValue);
      expect(
        fromYaml({ manifest: findPolicyEditorLayout().props('yamlEditorValue') }).rules,
      ).toStrictEqual(initialValue);

      findAddRuleButton().vm.$emit('click');
      await nextTick();

      const finalValue = [
        RULE_KEY_MAP[SCAN_EXECUTION_PIPELINE_RULE](),
        RULE_KEY_MAP[SCAN_EXECUTION_PIPELINE_RULE](),
      ];
      expect(findPolicyEditorLayout().props('policy').rules).toStrictEqual(finalValue);
      expect(
        fromYaml({ manifest: findPolicyEditorLayout().props('yamlEditorValue') }).rules,
      ).toStrictEqual(finalValue);
    });

    it('should update rule', async () => {
      const initialValue = [RULE_KEY_MAP[SCAN_EXECUTION_PIPELINE_RULE]()];
      expect(findPolicyEditorLayout().props('policy').rules).toStrictEqual(initialValue);
      expect(
        fromYaml({ manifest: findPolicyEditorLayout().props('yamlEditorValue') }).rules,
      ).toStrictEqual(initialValue);

      const finalValue = [{ ...RULE_KEY_MAP[SCAN_EXECUTION_PIPELINE_RULE](), branches: ['main'] }];
      findPolicyRuleBuilder().vm.$emit('changed', finalValue[0]);
      await nextTick();

      expect(findPolicyEditorLayout().props('policy').rules).toStrictEqual(finalValue);
      expect(
        fromYaml({ manifest: findPolicyEditorLayout().props('yamlEditorValue') }).rules,
      ).toStrictEqual(finalValue);
    });

    it('should remove rule', async () => {
      findAddRuleButton().vm.$emit('click');
      await nextTick();

      expect(findAllPolicyRuleBuilders()).toHaveLength(2);
      expect(findPolicyEditorLayout().props('policy').rules).toHaveLength(2);
      expect(
        fromYaml({ manifest: findPolicyEditorLayout().props('yamlEditorValue') }).rules,
      ).toHaveLength(2);

      findPolicyRuleBuilder().vm.$emit('remove', 1);
      await nextTick();

      expect(findAllPolicyRuleBuilders()).toHaveLength(1);
      expect(findPolicyEditorLayout().props('policy').rules).toHaveLength(1);
      expect(
        fromYaml({ manifest: findPolicyEditorLayout().props('yamlEditorValue') }).rules,
      ).toHaveLength(1);
    });
  });

  describe('policy action builder', () => {
    beforeEach(factory);

    it('should add new action', async () => {
      const initialValue = [buildScannerAction({ scanner: DEFAULT_SCANNER })];
      expect(findPolicyEditorLayout().props('policy').actions).toStrictEqual(initialValue);
      expect(
        fromYaml({ manifest: findPolicyEditorLayout().props('yamlEditorValue') }).actions,
      ).toStrictEqual(initialValue);

      findAddActionButton().vm.$emit('click');
      await nextTick();

      const finalValue = [
        buildScannerAction({ scanner: DEFAULT_SCANNER }),
        buildScannerAction({ scanner: DEFAULT_SCANNER }),
      ];
      expect(findPolicyEditorLayout().props('policy').actions).toStrictEqual(finalValue);
      expect(
        fromYaml({ manifest: findPolicyEditorLayout().props('yamlEditorValue') }).actions,
      ).toStrictEqual(finalValue);
    });

    it('should update action', async () => {
      const initialValue = [buildScannerAction({ scanner: DEFAULT_SCANNER })];
      expect(findPolicyEditorLayout().props('policy').actions).toStrictEqual(initialValue);
      expect(
        fromYaml({ manifest: findPolicyEditorLayout().props('yamlEditorValue') }).actions,
      ).toStrictEqual(initialValue);

      const finalValue = [buildScannerAction({ scanner: 'sast' })];
      findPolicyActionBuilder().vm.$emit('changed', finalValue[0]);
      await nextTick();

      expect(findPolicyEditorLayout().props('policy').actions).toStrictEqual(finalValue);
      expect(
        fromYaml({ manifest: findPolicyEditorLayout().props('yamlEditorValue') }).actions,
      ).toStrictEqual(finalValue);
    });

    it('should remove action', async () => {
      findAddActionButton().vm.$emit('click');
      await nextTick();

      expect(findAllPolicyActionBuilders()).toHaveLength(2);
      expect(findPolicyEditorLayout().props('policy').actions).toHaveLength(2);
      expect(
        fromYaml({ manifest: findPolicyEditorLayout().props('yamlEditorValue') }).actions,
      ).toHaveLength(2);

      findPolicyActionBuilder().vm.$emit('remove', 1);
      await nextTick();

      expect(findAllPolicyActionBuilders()).toHaveLength(1);
      expect(findPolicyEditorLayout().props('policy').actions).toHaveLength(1);
      expect(
        fromYaml({ manifest: findPolicyEditorLayout().props('yamlEditorValue') }).actions,
      ).toHaveLength(1);
    });
  });

  describe('parsing tags errors', () => {
    it.each`
      name                | errorKey                                         | expectedErrorMessage
      ${'tags '}          | ${POLICY_ACTION_BUILDER_TAGS_ERROR_KEY}          | ${RUNNER_TAGS_PARSING_ERROR}
      ${'DAST profiles '} | ${POLICY_ACTION_BUILDER_DAST_PROFILES_ERROR_KEY} | ${DAST_SCANNERS_PARSING_ERROR}
    `(
      'disables rule editor when parsing of $name fails',
      async ({ errorKey, expectedErrorMessage }) => {
        factory();
        findPolicyActionBuilder().vm.$emit('parsing-error', errorKey);
        await nextTick();

        expect(findPolicyEditorLayout().props('hasParsingError')).toBe(true);
        expect(findPolicyEditorLayout().props('parsingError')).toBe(expectedErrorMessage);
      },
    );
  });
});
