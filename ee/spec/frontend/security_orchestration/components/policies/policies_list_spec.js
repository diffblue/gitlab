import { GlTable, GlDrawer } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import PoliciesList from 'ee/security_orchestration/components/policies/policies_list.vue';
import PolicyDrawer from 'ee/security_orchestration/components/policy_drawer/policy_drawer.vue';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import projectScanExecutionPoliciesQuery from 'ee/security_orchestration/graphql/queries/project_scan_execution_policies.query.graphql';
import groupScanExecutionPoliciesQuery from 'ee/security_orchestration/graphql/queries/group_scan_execution_policies.query.graphql';
import projectScanResultPoliciesQuery from 'ee/security_orchestration/graphql/queries/project_scan_result_policies.query.graphql';
import groupScanResultPoliciesQuery from 'ee/security_orchestration/graphql/queries/group_scan_result_policies.query.graphql';

import {
  POLICY_SOURCE_OPTIONS,
  POLICY_TYPE_FILTER_OPTIONS,
} from 'ee/security_orchestration/components/policies/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { trimText } from 'helpers/text_helper';
import {
  projectScanExecutionPolicies,
  groupScanExecutionPolicies,
  projectScanResultPolicies,
  groupScanResultPolicies,
} from '../../mocks/mock_apollo';
import {
  mockGroupScanExecutionPolicy,
  mockScanExecutionPoliciesResponse,
} from '../../mocks/mock_scan_execution_policy_data';
import {
  mockScanResultPoliciesResponse,
  mockGroupScanResultPolicy,
} from '../../mocks/mock_scan_result_policy_data';

Vue.use(VueApollo);

const namespacePath = 'path/to/project/or/group';
const projectScanExecutionPoliciesSpy = projectScanExecutionPolicies(
  mockScanExecutionPoliciesResponse,
);
const groupScanExecutionPoliciesSpy = groupScanExecutionPolicies(mockScanExecutionPoliciesResponse);
const projectScanResultPoliciesSpy = projectScanResultPolicies(mockScanResultPoliciesResponse);
const groupScanResultPoliciesSpy = groupScanResultPolicies(mockScanResultPoliciesResponse);
const defaultRequestHandlers = {
  projectScanExecutionPolicies: projectScanExecutionPoliciesSpy,
  groupScanExecutionPolicies: groupScanExecutionPoliciesSpy,
  projectScanResultPolicies: projectScanResultPoliciesSpy,
  groupScanResultPolicies: groupScanResultPoliciesSpy,
};
describe('PoliciesList component', () => {
  let wrapper;
  let requestHandlers;

  const factory = (mountFn = mountExtended) => ({ handlers = {}, provide = {} } = {}) => {
    requestHandlers = {
      ...defaultRequestHandlers,
      ...handlers,
    };

    wrapper = mountFn(PoliciesList, {
      propsData: {
        documentationPath: 'documentation_path',
      },
      provide: {
        documentationPath: 'path/to/docs',
        namespacePath,
        namespaceType: NAMESPACE_TYPES.PROJECT,
        newPolicyPath: `${namespacePath}/-/security/policies/new`,
        ...provide,
      },
      apolloProvider: createMockApollo([
        [projectScanExecutionPoliciesQuery, requestHandlers.projectScanExecutionPolicies],
        [groupScanExecutionPoliciesQuery, requestHandlers.groupScanExecutionPolicies],
        [projectScanResultPoliciesQuery, requestHandlers.projectScanResultPolicies],
        [groupScanResultPoliciesQuery, requestHandlers.groupScanResultPolicies],
      ]),
      stubs: {
        PolicyDrawer: stubComponent(PolicyDrawer, {
          props: {
            ...PolicyDrawer.props,
            ...GlDrawer.props,
          },
        }),
        NoPoliciesEmptyState: true,
      },
    });
  };
  const mountShallowWrapper = factory(shallowMountExtended);
  const mountWrapper = factory();

  const findPolicySourceFilter = () => wrapper.findByTestId('policy-source-filter');
  const findPolicyTypeFilter = () => wrapper.findByTestId('policy-type-filter');
  const findPoliciesTable = () => wrapper.findComponent(GlTable);
  const findPolicyStatusCells = () => wrapper.findAllByTestId('policy-status-cell');
  const findPolicySourceCells = () => wrapper.findAllByTestId('policy-source-cell');
  const findPolicyTypeCells = () => wrapper.findAllByTestId('policy-type-cell');
  const findPolicyDrawer = () => wrapper.findByTestId('policyDrawer');

  describe('initial state', () => {
    it('renders closed editor drawer', () => {
      mountShallowWrapper({});

      const editorDrawer = findPolicyDrawer();
      expect(editorDrawer.exists()).toBe(true);
      expect(editorDrawer.props('open')).toBe(false);
    });

    it('fetches policies', () => {
      mountShallowWrapper({});

      expect(requestHandlers.projectScanExecutionPolicies).toHaveBeenCalledWith({
        fullPath: namespacePath,
        relationship: POLICY_SOURCE_OPTIONS.ALL.value,
      });
      expect(requestHandlers.groupScanExecutionPolicies).not.toHaveBeenCalled();
      expect(requestHandlers.projectScanResultPolicies).toHaveBeenCalledWith({
        fullPath: namespacePath,
        relationship: POLICY_SOURCE_OPTIONS.ALL.value,
      });
      expect(requestHandlers.groupScanResultPolicies).not.toHaveBeenCalled();
    });

    it("sets table's loading state", () => {
      mountShallowWrapper({});

      expect(findPoliciesTable().attributes('busy')).toBe('true');
    });
  });

  describe('given policies have been fetched', () => {
    let rows;

    beforeEach(async () => {
      mountWrapper();
      await waitForPromises();
      rows = wrapper.findAll('tr');
    });

    describe.each`
      rowIndex | expectedPolicyName                           | expectedPolicyType
      ${1}     | ${mockScanExecutionPoliciesResponse[0].name} | ${'Scan execution'}
      ${3}     | ${mockScanResultPoliciesResponse[0].name}    | ${'Scan result'}
    `('policy in row #$rowIndex', ({ rowIndex, expectedPolicyName, expectedPolicyType }) => {
      let row;

      beforeEach(() => {
        row = rows.at(rowIndex);
      });

      it(`renders ${expectedPolicyName} in the name cell`, () => {
        expect(row.findAll('td').at(1).text()).toBe(expectedPolicyName);
      });

      it(`renders ${expectedPolicyType} in the policy type cell`, () => {
        expect(row.findAll('td').at(2).text()).toBe(expectedPolicyType);
      });
    });

    it.each`
      description         | filterBy                                                 | hiddenTypes
      ${'scan execution'} | ${POLICY_TYPE_FILTER_OPTIONS.POLICY_TYPE_SCAN_EXECUTION} | ${[POLICY_TYPE_FILTER_OPTIONS.POLICY_TYPE_SCAN_RESULT]}
      ${'scan result'}    | ${POLICY_TYPE_FILTER_OPTIONS.POLICY_TYPE_SCAN_RESULT}    | ${[POLICY_TYPE_FILTER_OPTIONS.POLICY_TYPE_SCAN_EXECUTION]}
    `('policies filtered by $description type', async ({ filterBy, hiddenTypes }) => {
      findPolicyTypeFilter().vm.$emit('input', filterBy.value);
      await nextTick();

      expect(findPoliciesTable().text()).toContain(filterBy.text);
      hiddenTypes.forEach((hiddenType) => {
        expect(findPoliciesTable().text()).not.toContain(hiddenType.text);
      });
    });

    it('does emit `update-policy-list` and refetch scan execution policies on `shouldUpdatePolicyList` change to `true`', async () => {
      expect(projectScanExecutionPoliciesSpy).toHaveBeenCalledTimes(1);
      expect(wrapper.emitted('update-policy-list')).toBeUndefined();
      wrapper.setProps({ shouldUpdatePolicyList: true });
      await nextTick();
      expect(wrapper.emitted('update-policy-list')).toStrictEqual([[{}]]);
      expect(projectScanExecutionPoliciesSpy).toHaveBeenCalledTimes(2);
    });

    it('does not emit `update-policy-list` or refetch scan execution policies on `shouldUpdatePolicyList` change to `false`', async () => {
      wrapper.setProps({ shouldUpdatePolicyList: true });
      await nextTick();
      expect(projectScanExecutionPoliciesSpy).toHaveBeenCalledTimes(2);
      wrapper.setProps({ shouldUpdatePolicyList: false });
      await nextTick();
      expect(projectScanExecutionPoliciesSpy).toHaveBeenCalledTimes(2);
    });
  });

  describe('group-level policies', () => {
    beforeEach(async () => {
      mountShallowWrapper({
        provide: {
          namespacePath,
          namespaceType: NAMESPACE_TYPES.GROUP,
        },
      });
      await waitForPromises();
    });

    it('does not fetch policies', () => {
      expect(requestHandlers.projectScanExecutionPolicies).not.toHaveBeenCalled();
      expect(requestHandlers.groupScanExecutionPolicies).toHaveBeenCalledWith({
        fullPath: namespacePath,
        relationship: POLICY_SOURCE_OPTIONS.ALL.value,
      });
      expect(requestHandlers.projectScanResultPolicies).not.toHaveBeenCalled();
      expect(requestHandlers.groupScanResultPolicies).toHaveBeenCalledWith({
        fullPath: namespacePath,
        relationship: POLICY_SOURCE_OPTIONS.ALL.value,
      });
    });
  });

  describe('status column', () => {
    beforeEach(async () => {
      mountWrapper();
      await waitForPromises();
    });

    it('renders a checkmark icon for enabled policies', () => {
      const icon = findPolicyStatusCells().at(0).find('svg');

      expect(icon.exists()).toBe(true);
      expect(icon.props()).toMatchObject({
        name: 'check-circle-filled',
        ariaLabel: 'Enabled',
      });
    });

    it('renders a "Disabled" label for screen readers for disabled policies', () => {
      const span = findPolicyStatusCells().at(2).find('span');

      expect(span.exists()).toBe(true);
      expect(span.attributes('class')).toBe('gl-sr-only');
      expect(span.text()).toBe('Disabled');
    });
  });

  describe('source column', () => {
    beforeEach(async () => {
      mountWrapper();
      await waitForPromises();
    });

    it('renders when the policy is not inherited', () => {
      expect(findPolicySourceCells().at(0).text()).toBe('This project');
    });

    it('renders when the policy is inherited', () => {
      expect(trimText(findPolicySourceCells().at(1).text())).toBe(
        'Inherited from parent-group-name',
      );
    });
  });

  describe.each`
    description         | policy                                  | policyType         | editPolicyPath
    ${'scan execution'} | ${mockScanExecutionPoliciesResponse[0]} | ${'scanExecution'} | ${`${namespacePath}/-/security/policies/${encodeURIComponent(mockScanExecutionPoliciesResponse[0].name)}/edit?type=scan_execution_policy`}
    ${'scan result'}    | ${mockScanResultPoliciesResponse[0]}    | ${'scanResult'}    | ${`${namespacePath}/-/security/policies/${encodeURIComponent(mockScanResultPoliciesResponse[0].name)}/edit?type=scan_result_policy`}
  `('given there is a $description policy selected', ({ policy, policyType, editPolicyPath }) => {
    beforeEach(() => {
      mountShallowWrapper();
      findPoliciesTable().vm.$emit('row-selected', [policy]);
    });

    it('renders opened editor drawer', () => {
      const editorDrawer = findPolicyDrawer();
      expect(editorDrawer.exists()).toBe(true);
      expect(editorDrawer.props()).toMatchObject({
        editPolicyPath,
        open: true,
        policy,
        policyType,
      });
    });
  });

  describe('policy drawer', () => {
    it('should close drawer when new security project is selected', async () => {
      const scanExecutionPolicy = mockScanExecutionPoliciesResponse[0];

      mountShallowWrapper();
      findPoliciesTable().vm.$emit('row-selected', [scanExecutionPolicy]);
      await nextTick();

      expect(findPolicyDrawer().props('open')).toEqual(true);
      expect(findPolicyDrawer().props('policy')).toEqual(scanExecutionPolicy);

      wrapper.setProps({ shouldUpdatePolicyList: true });
      await nextTick();

      expect(findPolicyDrawer().props('open')).toEqual(false);
      expect(findPolicyDrawer().props('policy')).toEqual(null);
    });
  });

  describe('inherited filter', () => {
    beforeEach(async () => {
      mountWrapper({
        handlers: {
          projectScanExecutionPolicies: projectScanExecutionPolicies([
            mockGroupScanExecutionPolicy,
          ]),
          projectScanResultPolicies: projectScanResultPolicies([mockGroupScanResultPolicy]),
        },
      });
      await waitForPromises();

      findPolicySourceFilter().vm.$emit('input', POLICY_SOURCE_OPTIONS.INHERITED.value);
      await waitForPromises();
    });

    it('displays inherited policies only', () => {
      expect(findPolicySourceCells()).toHaveLength(2);
      expect(trimText(findPolicySourceCells().at(0).text())).toBe(
        'Inherited from parent-group-name',
      );
      expect(trimText(findPolicySourceCells().at(1).text())).toBe(
        'Inherited from parent-group-name',
      );
    });

    it('displays inherited scan execution policies', () => {
      expect(trimText(findPolicyTypeCells().at(0).text())).toBe(
        POLICY_TYPE_FILTER_OPTIONS.POLICY_TYPE_SCAN_EXECUTION.text,
      );
    });

    it('displays inherited scan result policies', () => {
      expect(trimText(findPolicyTypeCells().at(1).text())).toBe(
        POLICY_TYPE_FILTER_OPTIONS.POLICY_TYPE_SCAN_RESULT.text,
      );
    });
  });
});
