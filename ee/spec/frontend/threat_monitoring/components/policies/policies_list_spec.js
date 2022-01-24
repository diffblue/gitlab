import { GlTable, GlDrawer } from '@gitlab/ui';
import { createLocalVue } from '@vue/test-utils';
import { merge } from 'lodash';
import VueApollo from 'vue-apollo';
import { POLICY_TYPE_OPTIONS } from 'ee/threat_monitoring/components/constants';
import PoliciesList from 'ee/threat_monitoring/components/policies/policies_list.vue';
import PolicyDrawer from 'ee/threat_monitoring/components/policy_drawer/policy_drawer.vue';
import { PREDEFINED_NETWORK_POLICIES } from 'ee/threat_monitoring/constants';
import networkPoliciesQuery from 'ee/threat_monitoring/graphql/queries/network_policies.query.graphql';
import scanExecutionPoliciesQuery from 'ee/threat_monitoring/graphql/queries/scan_execution_policies.query.graphql';
import scanResultPoliciesQuery from 'ee/threat_monitoring/graphql/queries/scan_result_policies.query.graphql';
import createStore from 'ee/threat_monitoring/store';
import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  networkPolicies,
  scanExecutionPolicies,
  scanResultPolicies,
} from '../../mocks/mock_apollo';
import {
  mockNetworkPoliciesResponse,
  mockScanExecutionPoliciesResponse,
  mockScanResultPoliciesResponse,
} from '../../mocks/mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

const fullPath = 'project/path';
const environments = [
  {
    id: 2,
    global_id: 'gid://gitlab/Environment/2',
  },
  {
    id: 3,
    global_id: 'gid://gitlab/Environment/3',
  },
];
const networkPoliciesSpy = networkPolicies(mockNetworkPoliciesResponse);
const scanExecutionPoliciesSpy = scanExecutionPolicies(mockScanExecutionPoliciesResponse);
const scanResultPoliciesSpy = scanResultPolicies(mockScanResultPoliciesResponse);
const defaultRequestHandlers = {
  networkPolicies: networkPoliciesSpy,
  scanExecutionPolicies: scanExecutionPoliciesSpy,
  scanResultPolicies: scanResultPoliciesSpy,
};
const pendingHandler = jest.fn(() => new Promise(() => {}));

describe('PoliciesList component', () => {
  let store;
  let wrapper;
  let requestHandlers;

  const factory = (mountFn = mountExtended) => (options = {}) => {
    const { state = {}, handlers, ...wrapperOptions } = options;

    store = createStore();
    store.replaceState({
      ...store.state,
      threatMonitoring: {
        ...store.state.threatMonitoring,
        environments,
        hasEnvironment: true,
        currentEnvironmentId: environments[0].id,
        ...state.threatMonitoring,
      },
    });

    requestHandlers = {
      ...defaultRequestHandlers,
      ...handlers,
    };

    jest.spyOn(store, 'dispatch').mockImplementation(() => Promise.resolve());

    wrapper = mountFn(
      PoliciesList,
      merge(
        {
          propsData: {
            documentationPath: 'documentation_path',
            newPolicyPath: '/policies/new',
          },
          store,
          provide: {
            documentationPath: 'path/to/docs',
            newPolicyPath: 'path/to/policy',
            projectPath: fullPath,
            glFeatures: { scanResultPolicy: true },
          },
          apolloProvider: createMockApollo([
            [networkPoliciesQuery, requestHandlers.networkPolicies],
            [scanExecutionPoliciesQuery, requestHandlers.scanExecutionPolicies],
            [scanResultPoliciesQuery, requestHandlers.scanResultPolicies],
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
          localVue,
        },
        wrapperOptions,
      ),
    );
  };
  const mountShallowWrapper = factory(shallowMountExtended);
  const mountWrapper = factory();

  const findPolicyTypeFilter = () => wrapper.findByTestId('policy-type-filter');
  const findEnvironmentsPicker = () => wrapper.findByTestId('environment-picker');
  const findPoliciesTable = () => wrapper.findComponent(GlTable);
  const findPolicyStatusCells = () => wrapper.findAllByTestId('policy-status-cell');
  const findPolicyDrawer = () => wrapper.findByTestId('policyDrawer');
  const findAutodevopsAlert = () => wrapper.findByTestId('autodevopsAlert');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('initial state', () => {
    beforeEach(() => {
      mountShallowWrapper({
        handlers: {
          networkPolicies: pendingHandler,
        },
      });
    });

    it('renders EnvironmentPicker', () => {
      expect(findEnvironmentsPicker().exists()).toBe(true);
    });

    it('renders closed editor drawer', () => {
      const editorDrawer = findPolicyDrawer();
      expect(editorDrawer.exists()).toBe(true);
      expect(editorDrawer.props('open')).toBe(false);
    });

    it('does not render autodevops alert', () => {
      expect(findAutodevopsAlert().exists()).toBe(false);
    });

    it('fetches policies', () => {
      expect(requestHandlers.networkPolicies).toHaveBeenCalledWith({
        environmentId: environments[0].global_id,
        fullPath,
      });
      expect(requestHandlers.scanExecutionPolicies).toHaveBeenCalledWith({
        fullPath,
      });
    });

    it("sets table's loading state", () => {
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

    it('does render default network policies', () => {
      expect(findPolicyStatusCells()).toHaveLength(6);
    });

    it('fetches network policies on environment change', async () => {
      store.dispatch.mockReset();
      await store.commit('threatMonitoring/SET_CURRENT_ENVIRONMENT_ID', 3);
      expect(requestHandlers.networkPolicies).toHaveBeenCalledTimes(2);
      expect(requestHandlers.networkPolicies.mock.calls[1][0]).toEqual({
        fullPath: 'project/path',
        environmentId: environments[1].global_id,
      });
    });

    it('if network policies are filtered out, changing the environment does not trigger a fetch', async () => {
      store.dispatch.mockReset();
      expect(requestHandlers.networkPolicies).toHaveBeenCalledTimes(1);
      findPolicyTypeFilter().vm.$emit(
        'input',
        POLICY_TYPE_OPTIONS.POLICY_TYPE_SCAN_EXECUTION.value,
      );
      await store.commit('threatMonitoring/SET_CURRENT_ENVIRONMENT_ID', 2);
      expect(requestHandlers.networkPolicies).toHaveBeenCalledTimes(1);
    });

    describe.each`
      rowIndex | expectedPolicyName                           | expectedPolicyType
      ${1}     | ${mockScanExecutionPoliciesResponse[0].name} | ${'Scan execution'}
      ${2}     | ${mockScanResultPoliciesResponse[0].name}    | ${'Scan result'}
      ${3}     | ${mockNetworkPoliciesResponse[1].name}       | ${'Network'}
      ${4}     | ${mockNetworkPoliciesResponse[0].name}       | ${'Network'}
      ${5}     | ${PREDEFINED_NETWORK_POLICIES[0].name}       | ${'Network'}
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
      description         | filterBy                                          | hiddenTypes
      ${'network'}        | ${POLICY_TYPE_OPTIONS.POLICY_TYPE_NETWORK}        | ${[POLICY_TYPE_OPTIONS.POLICY_TYPE_SCAN_EXECUTION, POLICY_TYPE_OPTIONS.POLICY_TYPE_SCAN_RESULT]}
      ${'scan execution'} | ${POLICY_TYPE_OPTIONS.POLICY_TYPE_SCAN_EXECUTION} | ${[POLICY_TYPE_OPTIONS.POLICY_TYPE_NETWORK, POLICY_TYPE_OPTIONS.POLICY_TYPE_SCAN_RESULT]}
      ${'scan result'}    | ${POLICY_TYPE_OPTIONS.POLICY_TYPE_SCAN_RESULT}    | ${[POLICY_TYPE_OPTIONS.POLICY_TYPE_NETWORK, POLICY_TYPE_OPTIONS.POLICY_TYPE_SCAN_EXECUTION]}
    `('policies filtered by $description type', async ({ filterBy, hiddenTypes }) => {
      findPolicyTypeFilter().vm.$emit('input', filterBy.value);
      await wrapper.vm.$nextTick();

      expect(findPoliciesTable().text()).toContain(filterBy.text);
      hiddenTypes.forEach((hiddenType) => {
        expect(findPoliciesTable().text()).not.toContain(hiddenType.text);
      });
    });

    it('does emit `update-policy-list` and refetch scan execution policies on `shouldUpdatePolicyList` change to `false`', async () => {
      expect(scanExecutionPoliciesSpy).toHaveBeenCalledTimes(1);
      expect(wrapper.emitted('update-policy-list')).toBeUndefined();
      wrapper.setProps({ shouldUpdatePolicyList: true });
      await wrapper.vm.$nextTick();
      expect(wrapper.emitted('update-policy-list')).toStrictEqual([[false]]);
      expect(scanExecutionPoliciesSpy).toHaveBeenCalledTimes(2);
    });

    it('does not emit `update-policy-list` or refetch scan execution policies on `shouldUpdatePolicyList` change to `false`', async () => {
      wrapper.setProps({ shouldUpdatePolicyList: true });
      await wrapper.vm.$nextTick();
      wrapper.setProps({ shouldUpdatePolicyList: false });
      await wrapper.vm.$nextTick();
      expect(wrapper.emitted('update-policy-list')).toStrictEqual([[false]]);
      expect(scanExecutionPoliciesSpy).toHaveBeenCalledTimes(2);
    });
  });

  describe('status column', () => {
    beforeEach(async () => {
      mountWrapper();
      await waitForPromises();
    });

    it('renders a checkmark icon for enabled policies', () => {
      const icon = findPolicyStatusCells().at(1).find('svg');

      expect(icon.exists()).toBe(true);
      expect(icon.props()).toMatchObject({
        name: 'check-circle-filled',
        ariaLabel: 'Enabled',
      });
    });

    it('renders a "Disabled" label for screen readers for disabled policies', () => {
      const span = findPolicyStatusCells().at(4).find('span');

      expect(span.exists()).toBe(true);
      expect(span.attributes('class')).toBe('gl-sr-only');
      expect(span.text()).toBe('Disabled');
    });
  });

  describe('with allEnvironments enabled', () => {
    beforeEach(() => {
      mountWrapper({ state: { threatMonitoring: { allEnvironments: true } } });
    });

    it('renders environments column', () => {
      const environmentsHeader = findPoliciesTable().findAll('[role="columnheader"]').at(2);
      expect(environmentsHeader.text()).toContain('Environment(s)');
    });
  });

  describe.each`
    description                            | policy                                  | policyType         | editPolicyPath
    ${'network'}                           | ${mockNetworkPoliciesResponse[0]}       | ${'container'}     | ${'path/to/policy?environment_id=2&type=container_policy&kind=NetworkPolicy'}
    ${'container'}                         | ${mockNetworkPoliciesResponse[1]}       | ${'container'}     | ${'path/to/policy?environment_id=2&type=container_policy&kind=CiliumNetworkPolicy'}
    ${PREDEFINED_NETWORK_POLICIES[0].name} | ${PREDEFINED_NETWORK_POLICIES[0]}       | ${'container'}     | ${'path/to/policy?environment_id=2&type=container_policy&kind=CiliumNetworkPolicy'}
    ${PREDEFINED_NETWORK_POLICIES[1].name} | ${PREDEFINED_NETWORK_POLICIES[1]}       | ${'container'}     | ${'path/to/policy?environment_id=2&type=container_policy&kind=CiliumNetworkPolicy'}
    ${'scan execution'}                    | ${mockScanExecutionPoliciesResponse[0]} | ${'scanExecution'} | ${'path/to/policy?environment_id=2&type=scan_execution_policy'}
    ${'scan result'}                       | ${mockScanResultPoliciesResponse[0]}    | ${'scanResult'}    | ${'path/to/policy?environment_id=2&type=scan_result_policy'}
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

  describe('given an autodevops policy', () => {
    beforeEach(async () => {
      const autoDevOpsPolicy = {
        ...mockNetworkPoliciesResponse[1],
        name: 'auto-devops',
        fromAutoDevops: true,
      };
      mountShallowWrapper({
        handlers: {
          networkPolicies: networkPolicies([autoDevOpsPolicy]),
        },
      });
      await waitForPromises();
    });

    it('renders autodevops alert', () => {
      expect(findAutodevopsAlert().exists()).toBe(true);
    });
  });

  describe('given no environments', () => {
    beforeEach(async () => {
      mountWrapper({ state: { threatMonitoring: { hasEnvironment: false } } });
      await waitForPromises();
    });

    it('does not make a request for network policies', () => {
      expect(networkPoliciesSpy).not.toHaveBeenCalled();
    });

    it('does not render default network policies', () => {
      expect(findPolicyStatusCells()).toHaveLength(2);
    });
  });
});
