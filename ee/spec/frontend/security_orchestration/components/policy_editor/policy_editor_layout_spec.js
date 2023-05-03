import { nextTick } from 'vue';
import {
  GlAlert,
  GlFormInput,
  GlFormRadioGroup,
  GlFormTextarea,
  GlIcon,
  GlModal,
} from '@gitlab/ui';
import {
  EDITOR_MODE_YAML,
  POLICY_RUN_TIME_MESSAGE,
  POLICY_RUN_TIME_TOOLTIP,
  EDITOR_MODE_RULE,
  EDITOR_MODES,
} from 'ee/security_orchestration/components/policy_editor/constants';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import SegmentedControlButtonGroup from '~/vue_shared/components/segmented_control_button_group.vue';
import PolicyEditorLayout from 'ee/security_orchestration/components/policy_editor/policy_editor_layout.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockDastScanExecutionObject } from '../../mocks/mock_scan_execution_policy_data';
import { mockDefaultBranchesScanResultObject } from '../../mocks/mock_scan_result_policy_data';

describe('PolicyEditorLayout component', () => {
  let wrapper;
  let glTooltipDirectiveMock;
  const policiesPath = 'path/to/policy';
  const namespaceType = NAMESPACE_TYPES.PROJECT;
  const defaultProps = {
    policy: mockDastScanExecutionObject,
  };

  const factory = ({ propsData = {}, provide = {} } = {}) => {
    glTooltipDirectiveMock = jest.fn();
    wrapper = shallowMountExtended(PolicyEditorLayout, {
      directives: {
        GlTooltip: glTooltipDirectiveMock,
      },
      propsData: {
        ...defaultProps,
        ...propsData,
      },
      provide: {
        policiesPath,
        namespaceType,
        ...provide,
      },
      stubs: { PolicyYamlEditor: true },
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findNameInput = () => wrapper.findComponent(GlFormInput);
  const findDescriptionTextArea = () => wrapper.findComponent(GlFormTextarea);
  const findEnabledRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);
  const findDeletePolicyButton = () => wrapper.findByTestId('delete-policy');
  const findDeletePolicyModal = () => wrapper.findComponent(GlModal);
  const findEditorModeToggle = () => wrapper.findComponent(SegmentedControlButtonGroup);
  const findYamlModeSection = () => wrapper.findByTestId('policy-yaml-editor');
  const findRuleModeSection = () => wrapper.findByTestId('rule-editor');
  const findRuleModePreviewSection = () => wrapper.findByTestId('rule-editor-preview');
  const findSavePolicyButton = () => wrapper.findByTestId('save-policy');
  const findScanResultPolicyRunTimeInfo = () =>
    wrapper.findByTestId('scan-result-policy-run-time-info');
  const findScanResultPolicyRunTimeTooltip = () =>
    findScanResultPolicyRunTimeInfo().findComponent(GlIcon);

  describe('default behavior', () => {
    beforeEach(() => {
      factory();
    });

    it('does not display delete button', () => {
      expect(findDeletePolicyButton().exists()).toBe(false);
    });

    it('renders editor mode toggle options', () => {
      expect(findEditorModeToggle().props()).toEqual({
        value: EDITOR_MODE_RULE,
        options: EDITOR_MODES,
      });
    });

    it('disables the save button tooltip', () => {
      expect(glTooltipDirectiveMock.mock.calls[0][1].value.disabled).toBe(true);
    });

    it('does display the correct save button text when creating a new policy', () => {
      const saveButton = findSavePolicyButton();
      expect(saveButton.exists()).toBe(true);
      expect(saveButton.text()).toBe('Create policy');
    });

    it('emits properly with the current mode when the save button is clicked', () => {
      findSavePolicyButton().vm.$emit('click');
      expect(wrapper.emitted('save-policy')).toStrictEqual([['rule']]);
    });

    it('mode changes appropriately when new mode is selected', async () => {
      expect(findRuleModeSection().exists()).toBe(true);
      expect(findYamlModeSection().exists()).toBe(false);
      findEditorModeToggle().vm.$emit('input', EDITOR_MODE_YAML);
      await nextTick();
      expect(findRuleModeSection().exists()).toBe(false);
      expect(findYamlModeSection().exists()).toBe(true);
      expect(wrapper.emitted('update-editor-mode')).toStrictEqual([[EDITOR_MODE_YAML]]);
    });

    it('does display custom save button text', () => {
      const saveButton = findSavePolicyButton();
      expect(saveButton.exists()).toBe(true);
      expect(saveButton.attributes('disabled')).toBe(undefined);
      expect(saveButton.text()).toBe('Create policy');
    });
  });

  describe('editing a policy', () => {
    beforeEach(() => {
      factory({ propsData: { isEditing: true } });
    });

    it.each`
      component        | emit        | findFn                     | value
      ${'name'}        | ${'input'}  | ${findNameInput}           | ${'new name'}
      ${'description'} | ${'input'}  | ${findDescriptionTextArea} | ${'new description'}
      ${'enabled'}     | ${'change'} | ${findEnabledRadioGroup}   | ${true}
    `(
      'emits properly when $component input is updated',
      async ({ component, emit, findFn, value }) => {
        const vueComponent = findFn();
        expect(vueComponent.exists()).toBe(true);
        expect(wrapper.emitted('set-policy-property')).toBeUndefined();

        vueComponent.vm.$emit(emit, value);
        await nextTick();

        expect(wrapper.emitted('set-policy-property')).toEqual([[component, value]]);
      },
    );

    it('does not emit when the delete button is clicked', () => {
      findDeletePolicyButton().vm.$emit('click');
      expect(wrapper.emitted('remove-policy')).toStrictEqual(undefined);
    });

    it('emits properly when the delete modal is closed', () => {
      findDeletePolicyModal().vm.$emit('secondary');
      expect(wrapper.emitted('remove-policy')).toStrictEqual([[]]);
    });

    it('does not display the error alert', () => {
      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('rule mode', () => {
    beforeEach(() => {
      factory();
    });

    it.each`
      component                      | status                | findComponent                 | state
      ${'rule mode section'}         | ${'does display'}     | ${findRuleModeSection}        | ${true}
      ${'rule mode preview section'} | ${'does display'}     | ${findRuleModePreviewSection} | ${true}
      ${'yaml mode section'}         | ${'does not display'} | ${findYamlModeSection}        | ${false}
    `('$status the $component', ({ findComponent, state }) => {
      expect(findComponent().exists()).toBe(state);
    });
  });

  describe('yaml mode', () => {
    beforeEach(() => {
      factory({ propsData: { defaultEditorMode: EDITOR_MODE_YAML } });
    });

    it.each`
      component                      | status                | findComponent                 | state
      ${'rule mode section'}         | ${'does not display'} | ${findRuleModeSection}        | ${false}
      ${'rule mode preview section'} | ${'does not display'} | ${findRuleModePreviewSection} | ${false}
      ${'yaml mode section'}         | ${'does display'}     | ${findYamlModeSection}        | ${true}
    `('$status the $component', ({ findComponent, state }) => {
      expect(findComponent().exists()).toBe(state);
    });

    it('emits properly when yaml is updated', () => {
      const newManifest = 'new yaml!';
      findYamlModeSection().vm.$emit('input', newManifest);
      expect(wrapper.emitted('update-yaml')).toStrictEqual([[newManifest]]);
    });
  });

  describe('parsing error', () => {
    beforeEach(() => {
      factory({ propsData: { hasParsingError: true } });
    });

    it('displays the alert', () => {
      expect(findAlert().exists()).toBe(true);
    });

    it.each`
      component                  | findFn
      ${'name input'}            | ${findNameInput}
      ${'description text area'} | ${findDescriptionTextArea}
      ${'enabled radio group'}   | ${findEnabledRadioGroup}
    `('disables the $component', ({ findFn }) => {
      expect(findFn().attributes('disabled')).toBeDefined();
    });
  });

  describe('custom behavior', () => {
    it('displays the custom save button text when it is passed in', async () => {
      const customSaveButtonText = 'Custom Text';
      factory({ propsData: { customSaveButtonText } });
      await nextTick();
      expect(findSavePolicyButton().exists()).toBe(true);
      expect(findSavePolicyButton().text()).toBe(customSaveButtonText);
    });

    it('disables the save button when "disableUpdate" is true', async () => {
      factory({ propsData: { disableUpdate: true } });
      await nextTick();
      expect(findSavePolicyButton().exists()).toBe(true);
      expect(findSavePolicyButton().attributes('disabled')).toBeDefined();
    });

    it('enables the save button tooltip when "disableTooltip" is false', async () => {
      const customSaveTooltipText = 'Custom Test';
      factory({ propsData: { customSaveTooltipText, disableTooltip: false } });
      await nextTick();
      expect(glTooltipDirectiveMock.mock.calls[0][1].value.disabled).toBe(false);
      expect(glTooltipDirectiveMock.mock.calls[0][0].title).toBe(customSaveTooltipText);
    });
  });

  describe('policy runtime info', () => {
    it.each`
      title                                                           | currentNamespaceType       | propsData
      ${'does not display for project-level scan execution policies'} | ${NAMESPACE_TYPES.PROJECT} | ${{}}
      ${'does not display for group-level scan execution policies'}   | ${NAMESPACE_TYPES.GROUP}   | ${{}}
      ${'does not display for project-level scan result policies'}    | ${NAMESPACE_TYPES.PROJECT} | ${{ policy: mockDefaultBranchesScanResultObject }}
    `('$title', async ({ currentNamespaceType, propsData }) => {
      factory({ propsData, provide: { namespaceType: currentNamespaceType } });
      await nextTick();
      const policyRunTimeInfo = findScanResultPolicyRunTimeInfo();
      expect(policyRunTimeInfo.exists()).toBe(false);
    });

    it('does display for group-level scan result policies', async () => {
      factory({
        propsData: { policy: mockDefaultBranchesScanResultObject },
        provide: { namespaceType: NAMESPACE_TYPES.GROUP },
      });
      await nextTick();
      const policyRunTimeInfo = findScanResultPolicyRunTimeInfo();
      expect(policyRunTimeInfo.exists()).toBe(true);
      expect(policyRunTimeInfo.text()).toBe(POLICY_RUN_TIME_MESSAGE);
      const policyRunTimeTooltip = findScanResultPolicyRunTimeTooltip();
      expect(policyRunTimeTooltip.exists()).toBe(true);
      expect(glTooltipDirectiveMock.mock.calls[1][1].value).toBe(POLICY_RUN_TIME_TOOLTIP);
    });
  });

  describe('validation', () => {
    it('does not invalidate the name input on first load of the page', async () => {
      factory({ propsData: { policy: { ...mockDastScanExecutionObject, name: '' } } });
      await nextTick();
      expect(findNameInput().attributes('state')).toBe('true');
    });

    it('does not invalidate the name input when populated', async () => {
      factory();
      await nextTick();
      expect(findNameInput().attributes('state')).toBe('true');
    });

    it('does invalidate the name input when populated and then emptied', async () => {
      factory({ propsData: { policy: { ...mockDastScanExecutionObject, name: '' } } });
      await nextTick();
      findNameInput().vm.$emit('input', '');
      await nextTick();
      expect(findNameInput().attributes('state')).toBe(undefined);
    });

    it('disables save button when name is empty', async () => {
      factory({ propsData: { policy: { ...mockDastScanExecutionObject, name: '' } } });
      await nextTick();
      expect(findSavePolicyButton().props('disabled')).toBe(true);
    });

    it('enables save button when name is populated', async () => {
      factory();
      await nextTick();
      expect(findSavePolicyButton().props('disabled')).toBe(false);
    });
  });
});
