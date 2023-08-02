import { GlSprintf, GlCollapsibleListbox } from '@gitlab/ui';
import { __ } from '~/locale';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PolicyActionBuilder from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/policy_action_builder.vue';
import ProjectDastProfileSelector from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/scan_filters/project_dast_profile_selector.vue';
import projectRunnerTags from 'ee/vue_shared/components/runner_tags_dropdown/graphql/get_project_runner_tags.query.graphql';
import groupRunnerTags from 'ee/vue_shared/components/runner_tags_dropdown/graphql/get_group_runner_tags.query.graphql';
import GroupDastProfileSelector from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/scan_filters/group_dast_profile_selector.vue';
import GenericBaseLayoutComponent from 'ee/security_orchestration/components/policy_editor/generic_base_layout_component.vue';
import RunnerTagsFilter from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/scan_filters/runner_tags_filter.vue';
import CiVariablesSelectors from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/scan_filters/ci_variables_selectors.vue';
import ScanFilterSelector from 'ee/security_orchestration/components/policy_editor/scan_filter_selector.vue';
import { buildScannerAction } from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/lib';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import { SCANNER_HUMANIZED_TEMPLATE } from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/constants';
import { createMockApolloProvider } from 'ee_jest/security_configuration/dast_profiles/graphql/create_mock_apollo_provider';
import { RUNNER_TAG_LIST_MOCK } from 'ee_jest/vue_shared/components/runner_tags_dropdown/mocks/mocks';
import {
  CI_VARIABLE,
  FILTERS,
} from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/scan_filters/constants';

describe('PolicyActionBuilder', () => {
  let wrapper;
  let requestHandlers;
  const namespacePath = 'gid://gitlab/Project/20';
  const namespaceType = NAMESPACE_TYPES.PROJECT;
  const NEW_SCANNER = 'sast';
  const DEFAULT_ACTION = buildScannerAction({ scanner: 'dast' });

  const defaultHandlerValue = (type = 'project') =>
    jest.fn().mockResolvedValue({
      data: {
        [type]: {
          id: namespacePath,
          runners: {
            nodes: RUNNER_TAG_LIST_MOCK,
          },
        },
      },
    });

  const createApolloProvider = (handlers) => {
    requestHandlers = handlers;
    return createMockApolloProvider([
      [projectRunnerTags, requestHandlers],
      [groupRunnerTags, requestHandlers],
    ]);
  };

  const factory = ({
    propsData = {},
    stubs = {},
    handlers = defaultHandlerValue(),
    provide = {},
  } = {}) => {
    wrapper = shallowMountExtended(PolicyActionBuilder, {
      apolloProvider: createApolloProvider(handlers),
      propsData: {
        initAction: DEFAULT_ACTION,
        actionIndex: 0,
        ...propsData,
      },
      provide: {
        namespacePath,
        namespaceType,
        ...provide,
      },
      stubs: {
        GenericBaseLayoutComponent,
        GlSprintf,
        ...stubs,
      },
    });
  };

  const findActionSeperator = () => wrapper.findByTestId('action-and-label');
  const findCiVariablesSelectors = () => wrapper.findComponent(CiVariablesSelectors);
  const findGenericBaseLayoutComponent = () =>
    wrapper.findAllComponents(GenericBaseLayoutComponent).at(1);
  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findScanFilterSelector = () => wrapper.findComponent(ScanFilterSelector);
  const findSprintf = () => wrapper.findComponent(GlSprintf);
  const findTagsFilter = () => wrapper.findComponent(RunnerTagsFilter);
  const findProjectDastSelector = () => wrapper.findComponent(ProjectDastProfileSelector);
  const findGroupDastSelector = () => wrapper.findComponent(GroupDastProfileSelector);

  it('renders DAST as the default scanner', () => {
    factory();

    expect(findActionSeperator().exists()).toBe(false);
    expect(findDropdown().props()).toMatchObject({
      selected: 'dast',
      headerText: __('Select a scanner'),
    });
  });

  it('renders the action message correctly', () => {
    factory({ stubs: { GlSprintf: true } });
    expect(findSprintf().attributes('message')).toBe(SCANNER_HUMANIZED_TEMPLATE);
  });

  it('renders the scanner action with the newly selected scanner', async () => {
    factory();
    await findDropdown().vm.$emit('select', NEW_SCANNER);

    expect(findActionSeperator().exists()).toBe(false);
    expect(findDropdown().props('selected')).toBe(NEW_SCANNER);
  });

  it('renders an additional action with the action seperator', () => {
    factory({ propsData: { actionIndex: 1 } });
    expect(findActionSeperator().exists()).toBe(true);
  });

  it('emits the "changed" event with existing tags when an action scan type is changed', async () => {
    factory({ propsData: { initAction: { ...DEFAULT_ACTION, tags: ['production'] } } });
    expect(wrapper.emitted('changed')).toBe(undefined);

    await findDropdown().vm.$emit('select', NEW_SCANNER);
    expect(wrapper.emitted('changed')).toStrictEqual([
      [{ ...buildScannerAction({ scanner: NEW_SCANNER }), tags: ['production'] }],
    ]);
  });

  it('removes the variables when a action scan type is changed', async () => {
    factory({ propsData: { initAction: { ...DEFAULT_ACTION, variables: { key: 'value' } } } });
    await findDropdown().vm.$emit('select', NEW_SCANNER);

    expect(wrapper.emitted('changed')).toStrictEqual([
      [buildScannerAction({ scanner: NEW_SCANNER })],
    ]);
  });

  it('emits the "removed" event when an action is changed', async () => {
    factory();
    expect(wrapper.emitted('remove')).toBe(undefined);

    await findGenericBaseLayoutComponent().vm.$emit('remove');
    expect(wrapper.emitted('remove')).toStrictEqual([[]]);
  });

  describe('scan filters', () => {
    describe('runner tags filter', () => {
      it('shows runner tags filter', () => {
        factory();

        expect(findTagsFilter().exists()).toBe(true);
      });

      it('emits the "changed" event when action tags are changed', async () => {
        factory({ propsData: { initAction: { ...DEFAULT_ACTION, tags: ['staging'] } } });
        expect(wrapper.emitted('changed')).toBe(undefined);

        const NEW_TAGS = ['main', 'release'];
        await findTagsFilter().vm.$emit('input', { tags: NEW_TAGS });
        expect(wrapper.emitted('changed')).toStrictEqual([[{ ...DEFAULT_ACTION, tags: NEW_TAGS }]]);
      });

      it('emits an error when filter encounters a parsing error', async () => {
        factory({ propsData: { initAction: { ...DEFAULT_ACTION, tags: ['staging'] } } });
        await findTagsFilter().vm.$emit('error');

        expect(wrapper.emitted('parsing-error')).toHaveLength(1);
      });

      it('removes the "tags" property when the filter emits the "remove" event', async () => {
        factory({ propsData: { initAction: { ...DEFAULT_ACTION, tags: ['staging'] } } });
        await findTagsFilter().vm.$emit('remove');

        expect(wrapper.emitted('changed')).toStrictEqual([[DEFAULT_ACTION]]);
      });
    });

    describe('ci variable filter', () => {
      it('initially hides ci variable filter', () => {
        factory();

        expect(findCiVariablesSelectors().exists()).toBe(false);
      });

      it('emits "changed" with the updated variable when a variable is updated', () => {
        const VARIABLES = { key: 'new key', value: 'new value' };

        factory({
          propsData: {
            initAction: {
              ...DEFAULT_ACTION,
              variables: { [VARIABLES.key]: VARIABLES.value },
            },
            variables: { test: 'test_value' },
          },
        });
        const NEW_VARIABLES = { '': '' };
        findCiVariablesSelectors().vm.$emit('input', { variables: NEW_VARIABLES });
        expect(wrapper.emitted('changed')).toEqual([
          [{ ...DEFAULT_ACTION, variables: NEW_VARIABLES }],
        ]);
      });
    });

    describe('scan filter selector', () => {
      beforeEach(() => {
        factory();
      });

      it('displays the scan filter selector', () => {
        expect(findScanFilterSelector().props()).toMatchObject({
          filters: FILTERS,
          selected: { [CI_VARIABLE]: null },
        });
      });

      it('displays the ci variable filter when the scan filter selector selects it', async () => {
        await findScanFilterSelector().vm.$emit('select', CI_VARIABLE);
        expect(findCiVariablesSelectors().exists()).toBe(true);
      });
    });
  });

  describe('switching between group and project namespace', () => {
    it.each`
      namespaceTypeValue         | projectSelectorExist | groupSelectorExist
      ${NAMESPACE_TYPES.PROJECT} | ${true}              | ${false}
      ${NAMESPACE_TYPES.GROUP}   | ${false}             | ${true}
    `(
      'should display correct selector based on namespace type',
      ({ namespaceTypeValue, projectSelectorExist, groupSelectorExist }) => {
        factory({ provide: { namespaceType: namespaceTypeValue } });

        expect(findProjectDastSelector().exists()).toBe(projectSelectorExist);
        expect(findGroupDastSelector().exists()).toBe(groupSelectorExist);
      },
    );
  });
});
