import { nextTick } from 'vue';
import { GlDropdown, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PolicyActionBuilder from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/policy_action_builder.vue';
import { buildScannerAction } from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/lib';
import {
  ACTION_AND_LABEL,
  ACTION_THEN_LABEL,
} from 'ee/security_orchestration/components/policy_editor/constants';
import {
  DAST_HUMANIZED_TEMPLATE,
  SCANNER_HUMANIZED_TEMPLATE,
} from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/constants';

describe('PolicyActionBuilder', () => {
  let wrapper;

  const factory = ({ mountFn = mountExtended, props = {}, stubs = {} } = {}) => {
    wrapper = mountFn(PolicyActionBuilder, {
      propsData: {
        initAction: buildScannerAction({ scanner: 'dast' }),
        actionIndex: 0,
        ...props,
      },
      stubs: { GlDropdownItem: true, ...stubs },
    });
  };

  const findActionLabel = () => wrapper.findByTestId('action-component-label');
  const findRemoveButton = () => wrapper.findByRole('button', { name: __('Remove') });
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownOption = (scanner) => wrapper.findByText(scanner);
  const findSprintf = () => wrapper.findComponent(GlSprintf);
  const findTagsInput = () => wrapper.findByTestId('policy-tags-input');

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

    const branches = 'main,branch1,branch2';
    findTagsInput().vm.$emit('input', branches);
    await nextTick();

    expect(wrapper.emitted('changed')).toStrictEqual([
      [{ ...buildScannerAction({ scanner: 'dast' }), tags: branches.split(',') }],
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
});
