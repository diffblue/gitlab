import { GlLink, GlSprintf } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import MergeImmediatelyConfirmationDialog from 'ee/vue_merge_request_widget/components/merge_immediately_confirmation_dialog.vue';
import MergeTrainFailedPipelineConfirmationDialog from 'ee/vue_merge_request_widget/components/merge_train_failed_pipeline_confirmation_dialog.vue';
import ReadyToMerge from '~/vue_merge_request_widget/components/states/ready_to_merge.vue';
import {
  MWPS_MERGE_STRATEGY,
  MT_MERGE_STRATEGY,
  MTWPS_MERGE_STRATEGY,
} from '~/vue_merge_request_widget/constants';

describe('ReadyToMerge', () => {
  let wrapper;
  let vm;

  const service = {
    merge: () => Promise.resolve({ res: { data: { status: '' } } }),
    poll: () => {},
  };

  const mr = {
    isPipelineActive: false,
    headPipeline: { id: 'gid://gitlab/Pipeline/1', path: 'path/to/pipeline' },
    isPipelineFailed: false,
    isPipelinePassing: false,
    isMergeAllowed: true,
    onlyAllowMergeIfPipelineSucceeds: false,
    ffOnlyEnabled: false,
    hasCI: false,
    ciStatus: null,
    sha: '12345678',
    squash: false,
    squashIsEnabledByDefault: false,
    squashIsReadonly: false,
    squashIsSelected: false,
    commitMessage: 'This is the commit message',
    squashCommitMessage: 'This is the squash commit message',
    commitMessageWithDescription: 'This is the commit message description',
    shouldRemoveSourceBranch: true,
    canRemoveSourceBranch: false,
    canMerge: true,
    targetBranch: 'main',
    availableAutoMergeStrategies: [MWPS_MERGE_STRATEGY],
    mergeImmediatelyDocsPath: 'path/to/merge/immediately/docs',
    mergeTrainsCount: 0,
    userPermissions: { canMerge: true },
    mergeable: true,
  };

  const createComponent = (mrUpdates = {}, mountFn = shallowMount, data = {}) => {
    wrapper = mountFn(ReadyToMerge, {
      propsData: {
        mr: { ...mr, ...mrUpdates },
        service,
      },
      data() {
        return {
          loading: false,
          state: { ...mr, ...mrUpdates },
          ...data,
        };
      },
      stubs: {
        MergeImmediatelyConfirmationDialog,
        GlSprintf,
        GlLink,
        MergeTrainFailedPipelineConfirmationDialog,
      },
    });

    ({ vm } = wrapper);
  };

  const findMergeButton = () => wrapper.find('[data-testid="merge-button"]');
  const findMergeImmediatelyDropdown = () =>
    wrapper.find('[data-testid="merge-immediately-dropdown"]');
  const findMergeImmediatelyButton = () => wrapper.find('[data-testid="merge-immediately-button"]');
  const findMergeTrainFailedPipelineConfirmationDialog = () =>
    wrapper.findComponent(MergeTrainFailedPipelineConfirmationDialog);
  const findMergeImmediatelyConfirmationDialog = () =>
    wrapper.findComponent(MergeImmediatelyConfirmationDialog);
  const findAutoMergeHelperText = () => wrapper.find('[data-testid="auto-merge-helper-text"]');

  describe('Merge button text', () => {
    it.each`
      availableAutoMergeStrategies | mergeTrainsCount | expectedText
      ${[]}                        | ${0}             | ${'Merge'}
      ${[MWPS_MERGE_STRATEGY]}     | ${0}             | ${'Set auto-merge'}
      ${[MT_MERGE_STRATEGY]}       | ${0}             | ${'Merge'}
      ${[MT_MERGE_STRATEGY]}       | ${1}             | ${'Merge'}
      ${[MTWPS_MERGE_STRATEGY]}    | ${0}             | ${'Set auto-merge'}
      ${[MTWPS_MERGE_STRATEGY]}    | ${1}             | ${'Set auto-merge'}
    `(
      'displays $expectedText with merge strategy $availableAutoMergeStrategies and merge train count $mergeTrainsCount',
      ({ availableAutoMergeStrategies, mergeTrainsCount, expectedText }) => {
        createComponent({ availableAutoMergeStrategies, mergeTrainsCount });

        expect(findMergeButton().text()).toBe(expectedText);
      },
    );

    it('displays "Merge in progress"', async () => {
      createComponent({}, shallowMount, { isMergingImmediately: true });

      expect(findMergeButton().text()).toBe('Merge in progress');
    });
  });

  describe('Merge Immediately Dropdown', () => {
    it('should return false if no pipeline is active', () => {
      createComponent({
        headPipeline: { id: 'gid://gitlab/Pipeline/1', path: 'path/to/pipeline', active: false },
        onlyAllowMergeIfPipelineSucceeds: false,
      });

      expect(findMergeImmediatelyDropdown().exists()).toBe(false);
    });

    it('should return false if "Pipelines must succeed" is enabled for the current project', () => {
      createComponent({
        headPipeline: { id: 'gid://gitlab/Pipeline/1', path: 'path/to/pipeline', active: true },
        onlyAllowMergeIfPipelineSucceeds: true,
      });

      expect(findMergeImmediatelyDropdown().exists()).toBe(false);
    });

    it('should return true if the MR\'s pipeline is active and "Pipelines must succeed" is not enabled for the current project', () => {
      createComponent({
        headPipeline: { id: 'gid://gitlab/Pipeline/1', path: 'path/to/pipeline', active: true },
        onlyAllowMergeIfPipelineSucceeds: false,
      });

      expect(findMergeImmediatelyDropdown().exists()).toBe(true);
    });

    it('should return true when the merge train auto merge stategy is available', () => {
      createComponent({
        availableAutoMergeStrategies: [MT_MERGE_STRATEGY],
        headPipeline: { id: 'gid://gitlab/Pipeline/1', path: 'path/to/pipeline', active: false },
        onlyAllowMergeIfPipelineSucceeds: true,
      });

      expect(findMergeImmediatelyDropdown().exists()).toBe(true);
    });
  });

  describe('auto merge helper text', () => {
    it.each`
      availableAutoMergeStrategies | expectedText
      ${[MWPS_MERGE_STRATEGY]}     | ${'Merge when pipeline succeeds'}
      ${[MT_MERGE_STRATEGY]}       | ${'Add to merge train'}
      ${[MTWPS_MERGE_STRATEGY]}    | ${'Add to merge train when pipeline succeeds'}
    `(
      'displays $expectedText with merge strategy $availableAutoMergeStrategies',
      ({ availableAutoMergeStrategies, expectedText }) => {
        createComponent({ availableAutoMergeStrategies });

        expect(findAutoMergeHelperText().text()).toBe(expectedText);
      },
    );
  });

  describe('merge train failed confirmation dialog', () => {
    it.each`
      mergeStrategy           | isPipelineFailed | isVisible
      ${MT_MERGE_STRATEGY}    | ${true}          | ${true}
      ${MT_MERGE_STRATEGY}    | ${false}         | ${false}
      ${MTWPS_MERGE_STRATEGY} | ${true}          | ${false}
      ${MWPS_MERGE_STRATEGY}  | ${true}          | ${false}
    `(
      'with merge stragtegy $mergeStrategy and pipeline failed status of $isPipelineFailed we should show the modal: $isVisible',
      async ({ mergeStrategy, isPipelineFailed, isVisible }) => {
        createComponent({
          availableAutoMergeStrategies: [mergeStrategy],
          headPipeline: {
            id: 'gid://gitlab/Pipeline/1',
            path: 'path/to/pipeline',
            status: isPipelineFailed ? 'FAILED' : 'PASSED',
          },
        });
        const modalConfirmation = findMergeTrainFailedPipelineConfirmationDialog();

        if (!isVisible) {
          // need to mock if we don't show modal
          // to prevent internals from being invoked
          vm.handleMergeButtonClick = jest.fn();
        }

        await findMergeButton().vm.$emit('click');

        expect(modalConfirmation.props('visible')).toBe(isVisible);
      },
    );
  });

  describe('merge immediately warning dialog', () => {
    const clickMergeImmediately = async () => {
      expect(findMergeImmediatelyConfirmationDialog().exists()).toBe(true);

      findMergeImmediatelyConfirmationDialog().vm.show = jest.fn();

      vm.handleMergeButtonClick = jest.fn();

      findMergeImmediatelyDropdown().trigger('click');

      await nextTick();

      findMergeImmediatelyButton().trigger('click');

      await nextTick();
    };

    it('should show a warning dialog asking for confirmation if the user is trying to skip the merge train', async () => {
      createComponent({ availableAutoMergeStrategies: [MT_MERGE_STRATEGY] }, mount);

      await clickMergeImmediately();

      expect(findMergeImmediatelyConfirmationDialog().vm.show).toHaveBeenCalled();
      expect(vm.handleMergeButtonClick).not.toHaveBeenCalled();
    });

    it('should perform the merge when the user confirms their intent to merge immediately', async () => {
      createComponent({ availableAutoMergeStrategies: [MT_MERGE_STRATEGY] }, mount);

      await clickMergeImmediately();

      findMergeImmediatelyConfirmationDialog().vm.$emit('mergeImmediately');

      await nextTick();
      // false (no auto merge), true (merge immediately), true (confirmation clicked)
      expect(vm.handleMergeButtonClick).toHaveBeenCalledWith(false, true, true);
    });

    it('should not ask for confirmation in non-merge train scenarios', async () => {
      createComponent(
        {
          headPipeline: { id: 'gid://gitlab/Pipeline/1', path: 'path/to/pipeline', active: true },
          onlyAllowMergeIfPipelineSucceeds: false,
        },
        mount,
      );

      await clickMergeImmediately();

      expect(findMergeImmediatelyConfirmationDialog().vm.show).not.toHaveBeenCalled();
      expect(vm.handleMergeButtonClick).toHaveBeenCalled();
    });
  });

  describe('Merge train text', () => {
    describe('with any pipeline', () => {
      beforeEach(() => {
        createComponent({
          isPipelineFailed: true,
          availableAutoMergeStrategies: [MT_MERGE_STRATEGY],
          hasCI: true,
          onlyAllowMergeIfPipelineSucceeds: false,
        });
      });

      it('merge button text should contain "Merge" as the message', () => {
        expect(findMergeButton().text()).toBe('Merge');
      });
    });
  });
});
