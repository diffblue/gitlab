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
import { buildScannerAction } from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/lib';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import {
  DAST_HUMANIZED_TEMPLATE,
  SCANNER_HUMANIZED_TEMPLATE,
} from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/constants';
import { createMockApolloProvider } from 'ee_jest/security_configuration/dast_profiles/graphql/create_mock_apollo_provider';
import { RUNNER_TAG_LIST_MOCK } from 'ee_jest/vue_shared/components/runner_tags_dropdown/mocks/mocks';

describe('PolicyActionBuilder', () => {
  let wrapper;
  let requestHandlers;
  const namespacePath = 'gid://gitlab/Project/20';
  const namespaceType = NAMESPACE_TYPES.PROJECT;
  const scannerKey = 'sast';

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
    props = {},
    stubs = {},
    handlers = defaultHandlerValue(),
    provide = {},
  } = {}) => {
    wrapper = mountFn(PolicyActionBuilder, {
      apolloProvider: createApolloProvider(handlers),
      propsData: {
        initAction: buildScannerAction({ scanner: 'dast' }),
        actionIndex: 0,
        ...props,
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
  const findGenericBaseLayoutComponent = () =>
    wrapper.findAllComponents(GenericBaseLayoutComponent).at(1);
  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
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

    findDropdown().vm.$emit('select', scannerKey);
    await nextTick();

    expect(findActionSeperator().exists()).toBe(false);
    expect(findDropdown().props('selected')).toBe(scannerKey);
  });

  it('renders correctly the message with non-DAST scanner action', async () => {
    factory({
      mountFn: shallowMountExtended,
      props: {
        initAction: buildScannerAction({ scanner: 'sast' }),
      },
      stubs: { GenericBaseLayoutComponent },
    });
    await nextTick();

    expect(findSprintf().attributes('message')).toBe(SCANNER_HUMANIZED_TEMPLATE);
  });

  it('renders an additional action correctly', async () => {
    factory({ props: { actionIndex: 1 } });
    await nextTick();

    expect(findActionSeperator().exists()).toBe(true);
  });

  it('emits the "changed" event when an action scan type is changed', async () => {
    factory();
    await nextTick();

    expect(wrapper.emitted('changed')).toBe(undefined);

    findDropdown().vm.$emit('select', scannerKey);
    await nextTick();

    expect(wrapper.emitted('changed')).toStrictEqual([
      [buildScannerAction({ scanner: scannerKey })],
    ]);
  });

  it('emits the "changed" event when action tags are changed', async () => {
    factory();
    await nextTick();

    expect(wrapper.emitted('changed')).toBe(undefined);

    const branches = ['main', 'branch1', 'branch2'];
    findTagsList().vm.$emit('input', branches);
    await nextTick();

    expect(wrapper.emitted('changed')).toStrictEqual([
      [{ ...buildScannerAction({ scanner: 'dast' }), tags: branches }],
    ]);
  });

  it('emits the "removed" event when an action is changed', async () => {
    factory();
    await nextTick();

    expect(wrapper.emitted('remove')).toBe(undefined);

    findGenericBaseLayoutComponent().vm.$emit('remove');
    await nextTick();

    expect(wrapper.emitted('remove')).toStrictEqual([[]]);
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
