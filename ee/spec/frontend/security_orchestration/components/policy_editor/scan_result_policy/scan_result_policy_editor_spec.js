import { shallowMount } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import Api from 'ee/api';
import waitForPromises from 'helpers/wait_for_promises';
import PolicyEditorLayout from 'ee/security_orchestration/components/policy_editor/policy_editor_layout.vue';
import {
  DEFAULT_SCAN_RESULT_POLICY,
  fromYaml,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib';
import ScanResultPolicyEditor from 'ee/security_orchestration/components/policy_editor/scan_result_policy/scan_result_policy_editor.vue';
import {
  DEFAULT_ASSIGNED_POLICY_PROJECT,
  NAMESPACE_TYPES,
  USER_TYPE,
} from 'ee/security_orchestration/constants';
import {
  mockDefaultBranchesScanResultManifest,
  mockDefaultBranchesScanResultObject,
} from 'ee_jest/security_orchestration/mocks/mock_scan_result_policy_data';
import { unsupportedManifest } from 'ee_jest/security_orchestration/mocks/mock_data';
import { visitUrl } from '~/lib/utils/url_utility';

import { modifyPolicy } from 'ee/security_orchestration/components/policy_editor/utils';
import {
  SECURITY_POLICY_ACTIONS,
  EDITOR_MODE_RULE,
  PARSING_ERROR_MESSAGE,
} from 'ee/security_orchestration/components/policy_editor/constants';
import DimDisableContainer from 'ee/security_orchestration/components/policy_editor/dim_disable_container.vue';
import PolicyActionBuilder from 'ee/security_orchestration/components/policy_editor/scan_result_policy/policy_action_builder.vue';
import PolicyRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_result_policy/policy_rule_builder.vue';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_NOT_FOUND, HTTP_STATUS_OK } from '~/lib/utils/http_status';

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
  modifyPolicy: jest.fn().mockResolvedValue({ id: '2' }),
  isValidPolicy: jest.requireActual('ee/security_orchestration/components/policy_editor/utils')
    .isValidPolicy,
}));

describe('ScanResultPolicyEditor', () => {
  let mock;
  let wrapper;
  const defaultProjectPath = 'path/to/project';
  const policyEditorEmptyStateSvgPath = 'path/to/svg';
  const scanPolicyDocumentationPath = 'path/to/docs';
  const assignedPolicyProject = {
    branch: 'main',
    fullPath: 'path/to/existing-project',
  };
  const scanResultPolicyApprovers = [{ id: 1, username: 'the.one', state: 'active' }];

  const factory = ({ propsData = {}, provide = {} } = {}) => {
    wrapper = shallowMount(ScanResultPolicyEditor, {
      propsData: {
        assignedPolicyProject: DEFAULT_ASSIGNED_POLICY_PROJECT,
        ...propsData,
      },
      provide: {
        disableScanPolicyUpdate: false,
        policyEditorEmptyStateSvgPath,
        namespaceId: 1,
        namespacePath: defaultProjectPath,
        namespaceType: NAMESPACE_TYPES.PROJECT,
        scanPolicyDocumentationPath,
        scanResultPolicyApprovers,
        ...provide,
      },
    });
  };

  const factoryWithExistingPolicy = (policy = {}, provide = {}) => {
    return factory({
      propsData: {
        assignedPolicyProject,
        existingPolicy: { ...mockDefaultBranchesScanResultObject, ...policy },
        isEditing: true,
      },
      provide,
    });
  };

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findPolicyEditorLayout = () => wrapper.findComponent(PolicyEditorLayout);
  const findPolicyActionBuilder = () => wrapper.findComponent(PolicyActionBuilder);
  const findAllPolicyActionBuilders = () => wrapper.findAllComponents(PolicyActionBuilder);
  const findAddRuleButton = () => wrapper.find('[data-testid="add-rule"]');
  const findAllDisabledComponents = () => wrapper.findAllComponents(DimDisableContainer);
  const findAllRuleBuilders = () => wrapper.findAllComponents(PolicyRuleBuilder);

  const changesToRuleMode = () => {
    findPolicyEditorLayout().vm.$emit('update-editor-mode', EDITOR_MODE_RULE);
  };

  const verifiesParsingError = () => {
    expect(findPolicyEditorLayout().props('hasParsingError')).toBe(true);
    expect(findPolicyEditorLayout().attributes('parsingerror')).toBe(PARSING_ERROR_MESSAGE);
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('rendering', () => {
    it.each`
      prop                 | compareFn          | expected
      ${'yamlEditorValue'} | ${'toBe'}          | ${DEFAULT_SCAN_RESULT_POLICY}
      ${'hasParsingError'} | ${'toBe'}          | ${false}
      ${'policy'}          | ${'toStrictEqual'} | ${fromYaml({ manifest: DEFAULT_SCAN_RESULT_POLICY })}
    `(
      'passes the correct $prop prop to the PolicyEditorLayout component',
      ({ prop, compareFn, expected }) => {
        factory();

        expect(findPolicyEditorLayout().props(prop))[compareFn](expected);
      },
    );

    it('displays the initial rule and add rule button', () => {
      factory();

      expect(findAllRuleBuilders()).toHaveLength(1);
      expect(findAddRuleButton().exists()).toBe(true);
    });

    it('displays the initial action', () => {
      factory();

      expect(findAllPolicyActionBuilders()).toHaveLength(1);
      expect(findPolicyActionBuilder().props('existingApprovers')).toEqual(
        scanResultPolicyApprovers,
      );
    });

    describe('when a user is not an owner of the project', () => {
      it('displays the empty state with the appropriate properties', () => {
        factory({ provide: { disableScanPolicyUpdate: true } });

        const emptyState = findEmptyState();

        expect(emptyState.props('primaryButtonLink')).toMatch(scanPolicyDocumentationPath);
        expect(emptyState.props('primaryButtonLink')).toMatch('scan-result-policy-editor');
        expect(emptyState.props('svgPath')).toBe(policyEditorEmptyStateSvgPath);
      });
    });

    describe('scanResultRoleAction feature flag turned on', () => {
      const existingPolicyWithUserId = {
        actions: [{ type: 'require_approval', approvals_required: 1, user_approvers_ids: [1] }],
      };
      const existingUserApprover = {
        user: [{ id: 1, username: 'the.one', state: 'active', type: USER_TYPE }],
      };
      const nonExistingUserApprover = {
        user: [{ id: 2, username: 'the.two', state: 'active', type: USER_TYPE }],
      };

      it.each`
        title         | policy                      | approver                   | output
        ${'does not'} | ${{}}                       | ${existingUserApprover}    | ${false}
        ${'does'}     | ${{}}                       | ${nonExistingUserApprover} | ${true}
        ${'does not'} | ${existingPolicyWithUserId} | ${existingUserApprover}    | ${false}
        ${'does'}     | ${existingPolicyWithUserId} | ${nonExistingUserApprover} | ${true}
      `(
        '$title create an error when policy does not match existing approvers',
        async ({ policy, approver, output }) => {
          factoryWithExistingPolicy(policy, {
            glFeatures: {
              scanResultRoleAction: true,
            },
            scanResultPolicyApprovers: approver,
          });

          await changesToRuleMode();
          expect(findPolicyEditorLayout().props('hasParsingError')).toBe(output);
        },
      );
    });
  });

  describe('rule mode updates', () => {
    it.each`
      component        | oldValue | newValue
      ${'name'}        | ${''}    | ${'new policy name'}
      ${'description'} | ${''}    | ${'new description'}
      ${'enabled'}     | ${true}  | ${false}
    `('triggers a change on $component', ({ component, newValue, oldValue }) => {
      factory();

      expect(findPolicyEditorLayout().props('policy')[component]).toBe(oldValue);

      findPolicyEditorLayout().vm.$emit('set-policy-property', component, newValue);

      expect(findPolicyEditorLayout().props('policy')[component]).toBe(newValue);
    });

    describe('rule builder', () => {
      it('adds a new rule', async () => {
        const rulesCount = 1;
        factory();

        expect(findAllRuleBuilders()).toHaveLength(rulesCount);

        await findAddRuleButton().vm.$emit('click');

        expect(findAllRuleBuilders()).toHaveLength(rulesCount + 1);
      });

      it('hides add button when the limit of five rules has been reached', () => {
        const limit = 5;
        const rule = mockDefaultBranchesScanResultObject.rules[0];
        factoryWithExistingPolicy({ rules: [rule, rule, rule, rule, rule] });

        expect(findAllRuleBuilders()).toHaveLength(limit);
        expect(findAddRuleButton().exists()).toBe(false);
      });

      it('updates an existing rule', () => {
        const newValue = {
          type: 'scan_finding',
          branches: [],
          scanners: [],
          vulnerabilities_allowed: 1,
          severity_levels: [],
          vulnerability_states: [],
        };
        factory();

        findAllRuleBuilders().at(0).vm.$emit('changed', newValue);

        expect(wrapper.vm.policy.rules[0]).toEqual(newValue);
        expect(findPolicyEditorLayout().props('policy').rules[0].vulnerabilities_allowed).toBe(1);
      });

      it('deletes the initial rule', async () => {
        const initialRuleCount = 1;
        factory();

        expect(findAllRuleBuilders()).toHaveLength(initialRuleCount);

        await findAllRuleBuilders().at(0).vm.$emit('remove', 0);

        expect(findAllRuleBuilders()).toHaveLength(initialRuleCount - 1);
      });
    });

    describe('action builder', () => {
      it('updates policy action when edited', async () => {
        factory();

        const UPDATED_ACTION = { type: 'required_approval', group_approvers_ids: [1] };
        await findPolicyActionBuilder().vm.$emit('changed', UPDATED_ACTION);

        expect(findPolicyActionBuilder().props('initAction')).toEqual(UPDATED_ACTION);
      });
    });
  });

  describe('yaml mode updates', () => {
    beforeEach(factory);

    it('updates the policy yaml and policy object when "update-yaml" is emitted', async () => {
      await findPolicyEditorLayout().vm.$emit('update-yaml', mockDefaultBranchesScanResultManifest);

      expect(findPolicyEditorLayout().props('yamlEditorValue')).toBe(
        mockDefaultBranchesScanResultManifest,
      );
      expect(findPolicyEditorLayout().props('policy')).toMatchObject(
        mockDefaultBranchesScanResultObject,
      );
    });

    it('disables all rule mode related components when the yaml is invalid', async () => {
      await findPolicyEditorLayout().vm.$emit('update-yaml', unsupportedManifest);

      expect(findAllDisabledComponents().at(0).props('disabled')).toBe(true);
      expect(findAllDisabledComponents().at(1).props('disabled')).toBe(true);
    });
  });

  describe('CRUD operations', () => {
    it.each`
      status                            | action                             | event              | factoryFn                    | yamlEditorValue                          | currentlyAssignedPolicyProject
      ${'to save a new policy'}         | ${SECURITY_POLICY_ACTIONS.APPEND}  | ${'save-policy'}   | ${factory}                   | ${DEFAULT_SCAN_RESULT_POLICY}            | ${newlyCreatedPolicyProject}
      ${'to update an existing policy'} | ${SECURITY_POLICY_ACTIONS.REPLACE} | ${'save-policy'}   | ${factoryWithExistingPolicy} | ${mockDefaultBranchesScanResultManifest} | ${assignedPolicyProject}
      ${'to delete an existing policy'} | ${SECURITY_POLICY_ACTIONS.REMOVE}  | ${'remove-policy'} | ${factoryWithExistingPolicy} | ${mockDefaultBranchesScanResultManifest} | ${assignedPolicyProject}
    `(
      'navigates to the new merge request when "modifyPolicy" is emitted $status',
      async ({ action, event, factoryFn, yamlEditorValue, currentlyAssignedPolicyProject }) => {
        factoryFn();

        findPolicyEditorLayout().vm.$emit(event);

        await waitForPromises();

        expect(modifyPolicy).toHaveBeenCalledWith({
          action,
          assignedPolicyProject: currentlyAssignedPolicyProject,
          name:
            action === SECURITY_POLICY_ACTIONS.APPEND
              ? fromYaml({ manifest: yamlEditorValue }).name
              : mockDefaultBranchesScanResultObject.name,
          namespacePath: defaultProjectPath,
          yamlEditorValue,
        });
        expect(visitUrl).toHaveBeenCalledWith(
          `/${currentlyAssignedPolicyProject.fullPath}/-/merge_requests/2`,
        );
      },
    );
  });

  describe('errors', () => {
    it('creates an error for invalid yaml', async () => {
      factory();

      await findPolicyEditorLayout().vm.$emit('update-yaml', 'invalid manifest');

      verifiesParsingError();
    });

    it('creates an error when policy does not match existing approvers', async () => {
      factory();

      await changesToRuleMode();
      verifiesParsingError();
    });

    it('creates an error when policy scanners are invalid', async () => {
      factoryWithExistingPolicy({ rules: [{ scanners: ['cluster_image_scanning'] }] });

      await changesToRuleMode();
      verifiesParsingError();
    });

    it('does not create an error when policy matches existing approvers', async () => {
      factoryWithExistingPolicy();

      await changesToRuleMode();
      expect(findPolicyEditorLayout().props('hasParsingError')).toBe(false);
    });
  });

  describe('protected branches selector', () => {
    it.each`
      status                   | errorMessage
      ${HTTP_STATUS_OK}        | ${''}
      ${HTTP_STATUS_NOT_FOUND} | ${'The following branches do not exist on this development project: main. Please review all protected branches to ensure the values are accurate before updating this policy.'}
    `(
      'triggers error event with the correct content when the http status is $status',
      async ({ status, errorMessage }) => {
        const rule = { ...mockDefaultBranchesScanResultObject.rules[0], branches: ['main'] };

        mock.onGet('/api/undefined/projects/1/protected_branches/main').replyOnce(status, {});

        factoryWithExistingPolicy({ rules: [rule] });

        await findPolicyEditorLayout().vm.$emit('update-editor-mode', EDITOR_MODE_RULE);
        await waitForPromises();
        const errors = wrapper.emitted('error');

        expect(errors[errors.length - 1]).toEqual([errorMessage]);
      },
    );

    it('does not query protected branches when namespaceType is other than project', async () => {
      jest.spyOn(Api, 'projectProtectedBranch');

      factoryWithExistingPolicy({}, { namespaceType: NAMESPACE_TYPES.GROUP });

      await findPolicyEditorLayout().vm.$emit('update-editor-mode', EDITOR_MODE_RULE);
      await waitForPromises();

      expect(Api.projectProtectedBranch).not.toHaveBeenCalled();
    });
  });
});
