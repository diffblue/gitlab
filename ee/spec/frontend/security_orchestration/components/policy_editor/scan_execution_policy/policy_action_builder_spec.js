import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlDropdown, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createApolloProvider from 'helpers/mock_apollo_helper';
import RunnerTagsList from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/runner_tags_list.vue';
import PolicyActionBuilder from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/policy_action_builder.vue';
import projectRunnerTags from 'ee/security_orchestration/graphql/queries/get_project_runner_tags.query.graphql';
import groupRunnerTags from 'ee/security_orchestration/graphql/queries/get_group_runner_tags.query.graphql';
import { buildScannerAction } from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/lib';
import {
  ACTION_AND_LABEL,
  ACTION_THEN_LABEL,
} from 'ee/security_orchestration/components/policy_editor/constants';
import {
  DAST_HUMANIZED_TEMPLATE,
  SCANNER_HUMANIZED_TEMPLATE,
} from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/constants';
import { RUNNER_TAG_LIST_MOCK } from '../../../../on_demand_scans/mocks';

describe('PolicyActionBuilder', () => {
  let wrapper;
  let requestHandlers;
  const namespacePath = 'gid://gitlab/Project/20';
  const namespaceType = 'project';

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

  const createMockApolloProvider = (handlers) => {
    Vue.use(VueApollo);

    requestHandlers = handlers;
    return createApolloProvider([
      [projectRunnerTags, requestHandlers],
      [groupRunnerTags, requestHandlers],
    ]);
  };

  const factory = ({
    mountFn = mountExtended,
    props = {},
    stubs = {},
    handlers = defaultHandlerValue(),
  } = {}) => {
    wrapper = mountFn(PolicyActionBuilder, {
      apolloProvider: createMockApolloProvider(handlers),
      propsData: {
        initAction: buildScannerAction({ scanner: 'dast' }),
        actionIndex: 0,
        ...props,
      },
      provide: {
        namespacePath,
        namespaceType,
      },
      stubs: { GlDropdownItem: true, ...stubs },
    });
  };

  const findActionLabel = () => wrapper.findByTestId('action-component-label');
  const findRemoveButton = () => wrapper.findByRole('button', { name: __('Remove') });
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownOption = (scanner) => wrapper.findByText(scanner);
  const findSprintf = () => wrapper.findComponent(GlSprintf);
  const findTagsList = () => wrapper.findComponent(RunnerTagsList);

  it('renders correctly with DAST as the default scanner', async () => {
    factory({ stubs: { GlDropdown: true } });
    await nextTick();

    expect(findActionLabel().text()).toBe(ACTION_THEN_LABEL);
    expect(findDropdown().props('text')).toBe('DAST');
  });

  it('renders correctly the message with DAST as the default scanner', async () => {
    factory({ mountFn: shallowMountExtended, stubs: { GlDropdown: true } });
    await nextTick();

    expect(findSprintf().attributes('message')).toBe(DAST_HUMANIZED_TEMPLATE);
  });

  it('renders correctly with non-DAST scanner action', async () => {
    const scanner = 'SAST';

    factory({ stubs: { GlDropdown: true } });
    await nextTick();

    findDropdownOption(scanner).vm.$emit('click');
    await nextTick();

    expect(findActionLabel().text()).toBe(ACTION_THEN_LABEL);
    expect(findDropdown().props('text')).toBe(scanner);
  });

  it('renders correctly the message with non-DAST scanner action', async () => {
    factory({
      mountFn: shallowMountExtended,
      props: { initAction: buildScannerAction({ scanner: 'sast' }) },
      stubs: { GlDropdown: true },
    });
    await nextTick();

    expect(findSprintf().attributes('message')).toBe(SCANNER_HUMANIZED_TEMPLATE);
  });

  it('renders an additional action correctly', async () => {
    factory({ props: { actionIndex: 1 } });
    await nextTick();

    expect(findActionLabel().text()).toBe(ACTION_AND_LABEL);
  });

  it('emits the "changed" event when an action scan type is changed', async () => {
    factory();
    await nextTick();

    expect(wrapper.emitted('changed')).toBe(undefined);

    findDropdownOption('SAST').vm.$emit('click');
    await nextTick();

    expect(wrapper.emitted('changed')).toStrictEqual([[buildScannerAction({ scanner: 'sast' })]]);
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

    findRemoveButton().vm.$emit('click');
    await nextTick();

    expect(wrapper.emitted('remove')).toStrictEqual([[undefined]]);
  });

  describe('parsing error', () => {
    it('emits an error when tags parsing happens', () => {
      factory();
      findTagsList().vm.$emit('error');

      expect(wrapper.emitted('parsing-error')).toHaveLength(1);
    });
  });
});
