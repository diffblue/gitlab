import { GlModal, GlSegmentedControl } from '@gitlab/ui';
import { EDITOR_MODE_YAML } from 'ee/threat_monitoring/components/policy_editor/constants';
import PolicyEditorLayout from 'ee/threat_monitoring/components/policy_editor/policy_editor_layout.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('PolicyEditorLayout component', () => {
  let wrapper;
  const threatMonitoringPath = '/threat-monitoring';

  const factory = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(PolicyEditorLayout, {
      propsData: {
        ...propsData,
      },
      provide: {
        threatMonitoringPath,
      },
      stubs: { PolicyYamlEditor: true },
    });
  };

  const findDeletePolicyButton = () => wrapper.findByTestId('delete-policy');
  const findDeletePolicyModal = () => wrapper.findComponent(GlModal);
  const findEditorModeToggle = () => wrapper.findComponent(GlSegmentedControl);
  const findYamlModeSection = () => wrapper.findByTestId('policy-yaml-editor');
  const findRuleModeSection = () => wrapper.findByTestId('rule-editor');
  const findRuleModePreviewSection = () => wrapper.findByTestId('rule-editor-preview');
  const findSavePolicyButton = () => wrapper.findByTestId('save-policy');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default behavior', () => {
    beforeEach(() => {
      factory();
    });

    it.each`
      component               | status                | findComponent             | state
      ${'editor mode toggle'} | ${'does display'}     | ${findEditorModeToggle}   | ${true}
      ${'delete button'}      | ${'does not display'} | ${findDeletePolicyButton} | ${false}
    `('$status the $component', async ({ findComponent, state }) => {
      expect(findComponent().exists()).toBe(state);
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
      await findEditorModeToggle().vm.$emit('input', EDITOR_MODE_YAML);
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

    it('does not emit when the delete button is clicked', () => {
      findDeletePolicyButton().vm.$emit('click');
      expect(wrapper.emitted('remove-policy')).toStrictEqual(undefined);
    });

    it('emits properly when the delete modal is closed', () => {
      findDeletePolicyModal().vm.$emit('secondary');
      expect(wrapper.emitted('remove-policy')).toStrictEqual([[]]);
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
    `('$status the $component', async ({ findComponent, state }) => {
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
    `('$status the $component', async ({ findComponent, state }) => {
      expect(findComponent().exists()).toBe(state);
    });

    it('emits properly when yaml is updated', () => {
      const newManifest = 'new yaml!';
      findYamlModeSection().vm.$emit('input', newManifest);
      expect(wrapper.emitted('update-yaml')).toStrictEqual([[newManifest]]);
    });
  });

  describe('disabled actions', () => {
    it('disables the save button', async () => {
      factory({ propsData: { disableUpdate: true } });
      expect(findSavePolicyButton().exists()).toBe(true);
      expect(findSavePolicyButton().attributes('disabled')).toBe('true');
    });
  });
});
