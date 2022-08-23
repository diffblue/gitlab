import { nextTick } from 'vue';
import { GlDropdown } from '@gitlab/ui';
import { __ } from '~/locale';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import PolicyActionBuilder from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/policy_action_builder.vue';
import { buildScannerAction } from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/lib';
import {
  ACTION_AND_LABEL,
  ACTION_THEN_LABEL,
} from 'ee/security_orchestration/components/policy_editor/constants';

describe('PolicyActionBuilder', () => {
  let wrapper;

  const factory = ({ props = {}, stubs = {} } = {}) => {
    wrapper = mountExtended(PolicyActionBuilder, {
      propsData: {
        initAction: buildScannerAction('dast'),
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

  it('renders correctly with DAST as the default scanner', async () => {
    factory({ stubs: { GlDropdown: true } });
    await nextTick();

    expect(findActionLabel().text()).toBe(ACTION_THEN_LABEL);
    expect(findDropdown().props('text')).toBe('DAST');
  });

  it('renders an additional action correctly', async () => {
    factory({ props: { actionIndex: 1 } });
    await nextTick();

    expect(findActionLabel().text()).toBe(ACTION_AND_LABEL);
  });

  it('emits the "changed" event when an action is changed', async () => {
    factory();
    await nextTick();

    expect(wrapper.emitted('changed')).toBe(undefined);

    findDropdownOption('SAST').vm.$emit('click');
    await nextTick();

    expect(wrapper.emitted('changed')).toStrictEqual([[buildScannerAction('sast')]]);
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
