import { GlFormGroup, GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GenericBaseLayoutComponent from 'ee/security_orchestration/components/policy_editor/generic_base_layout_component.vue';
import RunnerTagsFilter from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/scan_filters/runner_tags_filter.vue';
import RunnerTagsList from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/scan_filters/runner_tags_list.vue';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';

describe('RunnerTagsFilter', () => {
  let wrapper;

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(RunnerTagsFilter, {
      propsData: {
        ...propsData,
      },
      provide: {
        namespacePath: 'gitlab-org/testPath',
        namespaceType: NAMESPACE_TYPES.PROJECT,
      },
      stubs: { GenericBaseLayoutComponent, GlFormGroup },
    });
  };

  const findGenericBaseLayoutComponent = () => wrapper.findComponent(GenericBaseLayoutComponent);
  const findRunnerTagsList = () => wrapper.findComponent(RunnerTagsList);
  const findHelpIcon = () => wrapper.findComponent(GlIcon);

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays the runners tag list and help icon', () => {
      expect(findRunnerTagsList().exists()).toBe(true);
      expect(findHelpIcon().exists()).toBe(true);
    });

    it('emits "input" when the tags are updated', () => {
      const NEW_TAGS = ['one'];
      expect(wrapper.emitted('input')).toBe(undefined);
      findRunnerTagsList().vm.$emit('input', NEW_TAGS);
      expect(wrapper.emitted('input')).toEqual([[{ tags: NEW_TAGS }]]);
    });

    it('emits "remove" when the tags filter is removed', () => {
      expect(wrapper.emitted('remove')).toBe(undefined);
      findGenericBaseLayoutComponent().vm.$emit('remove');
      expect(wrapper.emitted('remove')).toEqual([[]]);
    });
  });
});
