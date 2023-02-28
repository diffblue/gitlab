import { sprintf } from '~/locale';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MergeChecksApp from 'ee/merge_checks/components/merge_checks_app.vue';
import { I18N } from 'ee/merge_checks/constants';

describe('MergeChecksApp', () => {
  const defaultType = 'project';
  const defaultGroupName = 'test';
  const defaultCheckValue = {
    locked: false,
    value: false,
  };

  let wrapper;

  const createWrapper = (provides = {}) => {
    wrapper = shallowMountExtended(MergeChecksApp, {
      provide: {
        sourceType: defaultType,
        parentGroupName: defaultGroupName,
        pipelineMustSucceed: defaultCheckValue,
        allowMergeOnSkippedPipeline: defaultCheckValue,
        onlyAllowMergeIfAllResolved: defaultCheckValue,
        ...provides,
      },
    });
  };

  const findOnlyAllowMergeWhenPipelineSucceeds = () =>
    wrapper.findByTestId('allow_merge_if_pipeline_succeeds_checkbox');

  const findOnlyAllowMergeWhenPipelineSucceedsInput = () =>
    wrapper.find('input[name$="[only_allow_merge_if_pipeline_succeeds]"]');

  describe('sourceType', () => {
    it('with default sourceType', () => {
      createWrapper();
      expect(findOnlyAllowMergeWhenPipelineSucceedsInput().attributes('name')).toBe(
        `${defaultType}[only_allow_merge_if_pipeline_succeeds]`,
      );
    });

    it('with other sourceType', () => {
      const sourceType = 'new-type';
      createWrapper({
        sourceType,
      });

      expect(findOnlyAllowMergeWhenPipelineSucceedsInput().attributes('name')).toBe(
        `${sourceType}[only_allow_merge_if_pipeline_succeeds]`,
      );
    });
  });

  describe('group name', () => {
    it('with default groupName', () => {
      createWrapper();

      expect(findOnlyAllowMergeWhenPipelineSucceeds().attributes('lockedtext')).toBe(
        sprintf(I18N.lockedText, { groupName: defaultGroupName }),
      );
    });

    it('with other groupName', () => {
      const parentGroupName = 'new-name';
      createWrapper({ parentGroupName });

      expect(findOnlyAllowMergeWhenPipelineSucceeds().attributes('lockedtext')).toBe(
        sprintf(I18N.lockedText, { groupName: parentGroupName }),
      );
    });
  });

  describe('binding value', () => {
    it('should be able to bind and mutate value', async () => {
      createWrapper();
      const checkbox = findOnlyAllowMergeWhenPipelineSucceeds();

      expect(checkbox.props('checked')).toBe(defaultCheckValue.value);

      await checkbox.vm.$emit('input');
      expect(checkbox.props('checked')).toBe(true);
      await checkbox.vm.$emit('input');
      expect(checkbox.props('checked')).toBe(false);
    });
  });

  describe('skipped pipeline', () => {
    const findSkippedPipelineCheckbox = () =>
      wrapper.findByTestId('allow_merge_on_skipped_pipeline_checkbox');

    it('should be corresponding with pipeline must succeeds', () => {
      createWrapper();

      expect(findSkippedPipelineCheckbox().props('locked')).toBe(true);
      expect(findSkippedPipelineCheckbox().props('lockedText')).toBe(
        I18N.lockedUponPipelineMustSucceed,
      );

      createWrapper({
        pipelineMustSucceed: {
          value: true,
          locked: false,
        },
      });

      expect(findSkippedPipelineCheckbox().props('locked')).toBe(false);
      expect(findSkippedPipelineCheckbox().props('lockedText')).toBe(
        sprintf(I18N.lockedText, { groupName: defaultGroupName }),
      );
    });

    it('should be locked and unchecked when preceding condition unmet', async () => {
      createWrapper({
        pipelineMustSucceed: {
          value: true,
          locked: false,
        },
        allowMergeOnSkippedPipeline: {
          value: true,
          locked: false,
        },
      });

      expect(findSkippedPipelineCheckbox().props('locked')).toBe(false);
      expect(findSkippedPipelineCheckbox().props('checked')).toBe(true);

      await findOnlyAllowMergeWhenPipelineSucceeds().vm.$emit('input');

      expect(findSkippedPipelineCheckbox().props('locked')).toBe(true);
      expect(findSkippedPipelineCheckbox().props('checked')).toBe(false);
    });
  });
});
