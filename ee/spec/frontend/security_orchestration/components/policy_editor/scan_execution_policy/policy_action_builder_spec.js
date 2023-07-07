import { nextTick } from 'vue';
import { GlSprintf, GlCollapsibleListbox } from '@gitlab/ui';
import { __ } from '~/locale';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RunnerTagsList from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/runner_tags_list.vue';
import PolicyActionBuilder from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/policy_action_builder.vue';
import ProjectDastProfileSelector from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/project_dast_profile_selector.vue';
import projectRunnerTags from 'ee/vue_shared/components/runner_tags_dropdown/graphql/get_project_runner_tags.query.graphql';
import groupRunnerTags from 'ee/vue_shared/components/runner_tags_dropdown/graphql/get_group_runner_tags.query.graphql';
import GroupDastProfileSelector from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/group_dast_profile_selector.vue';
import GenericBaseLayoutComponent from 'ee/security_orchestration/components/policy_editor/generic_base_layout_component.vue';
import CiVariablesSelectors from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/scan_filters/ci_variables_selectors.vue';
import ScanFilterSelector from 'ee/security_orchestration/components/policy_editor/scan_filter_selector.vue';
import { buildScannerAction } from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/lib';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import {
  DAST_HUMANIZED_TEMPLATE,
  SCANNER_HUMANIZED_TEMPLATE,
} from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/constants';
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
    mountFn = mountExtended,
    propsData = {},
    stubs = {},
    handlers = defaultHandlerValue(),
    provide = {},
  } = {}) => {
    wrapper = mountFn(PolicyActionBuilder, {
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
      stubs: { ...stubs },
    });
  };

  const findActionSeperator = () => wrapper.findByTestId('action-and-label');
  const findCiVariablesSelectors = () => wrapper.findComponent(CiVariablesSelectors);
  const findGenericBaseLayoutComponent = () =>
    wrapper.findAllComponents(GenericBaseLayoutComponent).at(1);
  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findScanFilterSelector = () => wrapper.findComponent(ScanFilterSelector);
  const findSprintf = () => wrapper.findComponent(GlSprintf);
  const findTagsList = () => wrapper.findComponent(RunnerTagsList);
  const findProjectDastSelector = () => wrapper.findComponent(ProjectDastProfileSelector);
  const findGroupDastSelector = () => wrapper.findComponent(GroupDastProfileSelector);

  it('renders correctly with DAST as the default scanner', async () => {
    factory({ stubs: { GlCollapsibleListbox: true } });
    await nextTick();

    expect(findActionSeperator().exists()).toBe(false);
    expect(findDropdown().props()).toMatchObject({
      selected: 'dast',
      headerText: __('Select a scanner'),
    });
  });

  it('renders correctly the message with DAST as the default scanner', async () => {
    factory({
      mountFn: shallowMountExtended,
      stubs: { GenericBaseLayoutComponent, GlCollapsibleListbox: true },
    });
    await nextTick();

    expect(findSprintf().attributes('message')).toBe(DAST_HUMANIZED_TEMPLATE);
  });

  it('renders correctly with non-DAST scanner action', async () => {
    factory({ stubs: { GlCollapsibleListbox: true } });
    await nextTick();

    findDropdown().vm.$emit('select', NEW_SCANNER);
    await nextTick();

    expect(findActionSeperator().exists()).toBe(false);
    expect(findDropdown().props('selected')).toBe(NEW_SCANNER);
  });

  it('renders correctly the message with non-DAST scanner action', async () => {
    factory({
      mountFn: shallowMountExtended,
      propsData: {
        initAction: buildScannerAction({ scanner: 'sast' }),
      },
      stubs: { GenericBaseLayoutComponent },
    });
    await nextTick();

    expect(findSprintf().attributes('message')).toBe(SCANNER_HUMANIZED_TEMPLATE);
  });

  it('renders an additional action correctly', async () => {
    factory({ propsData: { actionIndex: 1 } });
    await nextTick();

    expect(findActionSeperator().exists()).toBe(true);
  });

  it('emits the "changed" event when an action scan type is changed', async () => {
    factory({ propsData: { initAction: { ...DEFAULT_ACTION, tags: ['production'] } } });
    await nextTick();

    expect(wrapper.emitted('changed')).toBe(undefined);

    findDropdown().vm.$emit('select', NEW_SCANNER);
    await nextTick();

    expect(wrapper.emitted('changed')).toStrictEqual([
      [{ ...buildScannerAction({ scanner: NEW_SCANNER }), tags: ['production'] }],
    ]);
  });

  it('removes the variables when a action scan type is changed', async () => {
    factory({ propsData: { initAction: { ...DEFAULT_ACTION, variables: { key: 'value' } } } });
    await nextTick();

    findDropdown().vm.$emit('select', NEW_SCANNER);
    await nextTick();

    expect(wrapper.emitted('changed')).toStrictEqual([
      [buildScannerAction({ scanner: NEW_SCANNER })],
    ]);
  });

  it('emits the "changed" event when action tags are changed', async () => {
    factory({ propsData: { initAction: { ...DEFAULT_ACTION, tags: ['staging'] } } });
    await nextTick();

    expect(wrapper.emitted('changed')).toBe(undefined);

    const NEW_TAGS = ['main', 'release'];
    findTagsList().vm.$emit('input', NEW_TAGS);
    await nextTick();

    expect(wrapper.emitted('changed')).toStrictEqual([[{ ...DEFAULT_ACTION, tags: NEW_TAGS }]]);
  });

  it('emits the "removed" event when an action is changed', async () => {
    factory();
    await nextTick();

    expect(wrapper.emitted('remove')).toBe(undefined);

    findGenericBaseLayoutComponent().vm.$emit('remove');
    await nextTick();

    expect(wrapper.emitted('remove')).toStrictEqual([[]]);
  });

  describe('scan filters', () => {
    it('initially hides ci variable filter', () => {
      factory();
      expect(findCiVariablesSelectors().exists()).toBe(false);
    });

    describe('ci variable filter', () => {
      const VARIABLES = { key: 'new key', value: 'new value' };

      beforeEach(() => {
        factory({
          propsData: {
            initAction: {
              ...DEFAULT_ACTION,
              variables: { [VARIABLES.key]: VARIABLES.value },
            },
            variables: { test: 'test_value' },
          },
        });
      });

      it('emits "changed" with the updated variable when a variable is updated', () => {
        const NEW_VARIABLES = { '': '' };
        findCiVariablesSelectors().vm.$emit('input', { variables: NEW_VARIABLES });
        expect(wrapper.emitted('changed')).toEqual([
          [{ ...DEFAULT_ACTION, variables: NEW_VARIABLES }],
        ]);
      });

      it('emits "error" with the correct error message when a variable error occurs', () => {
        findCiVariablesSelectors().vm.$emit('remove');
        expect(wrapper.emitted('parsing-error')).toEqual([['variables']]);
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

  describe('parsing error', () => {
    it('emits an error when tags parsing happens', () => {
      factory();
      findTagsList().vm.$emit('error');

      expect(wrapper.emitted('parsing-error')).toHaveLength(1);
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
