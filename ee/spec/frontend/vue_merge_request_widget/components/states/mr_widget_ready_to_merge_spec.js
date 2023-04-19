import { GlLink, GlSprintf } from '@gitlab/ui';
import { nextTick } from 'vue';
import MergeImmediatelyConfirmationDialog from 'ee/vue_merge_request_widget/components/merge_immediately_confirmation_dialog.vue';
import MergeTrainFailedPipelineConfirmationDialog from 'ee/vue_merge_request_widget/components/merge_train_failed_pipeline_confirmation_dialog.vue';
import MergeTrainHelperIcon from 'ee/vue_merge_request_widget/components/merge_train_helper_icon.vue';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import ReadyToMerge from '~/vue_merge_request_widget/components/states/ready_to_merge.vue';
import {
  MWPS_MERGE_STRATEGY,
  MT_MERGE_STRATEGY,
  MTWPS_MERGE_STRATEGY,
} from '~/vue_merge_request_widget/constants';
import { MERGE_TRAIN_BUTTON_TEXT } from '~/vue_merge_request_widget/i18n';

describe('ReadyToMerge', () => {
  let wrapper;
  const showMock = jest.fn();

  const service = {
    merge: () => Promise.resolve({ res: { data: { status: '' } } }),
    poll: () => {},
  };

  const activePipeline = {
    id: 1,
    path: 'path/to/pipeline',
    active: true,
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
    transitionStateMachine: jest.fn(),
  };

  const createComponent = (mrUpdates = {}, mountFn = shallowMountExtended, data = {}) => {
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
        MergeImmediatelyConfirmationDialog: stubComponent(MergeImmediatelyConfirmationDialog, {
          methods: { show: showMock },
        }),
        MergeTrainHelperIcon,
        GlSprintf,
        GlLink,
        MergeTrainFailedPipelineConfirmationDialog,
      },
    });
  };

  const findMergeButton = () => wrapper.findByTestId('merge-button');
  const findMergeImmediatelyDropdown = () => wrapper.findByTestId('merge-immediately-dropdown');
  const findMergeImmediatelyButton = () => wrapper.findByTestId('merge-immediately-button');
  const findMergeTrainHelperIcon = () => wrapper.findComponent(MergeTrainHelperIcon);
  const findMergeTrainFailedPipelineConfirmationDialog = () =>
    wrapper.findComponent(MergeTrainFailedPipelineConfirmationDialog);
  const findMergeImmediatelyConfirmationDialog = () =>
    wrapper.findComponent(MergeImmediatelyConfirmationDialog);

  describe('Merge button text', () => {
    it.each`
      availableAutoMergeStrategies | mergeTrainsCount | expectedText
      ${[]}                        | ${0}             | ${'Merge'}
      ${[MWPS_MERGE_STRATEGY]}     | ${0}             | ${'Merge when pipeline succeeds'}
      ${[MT_MERGE_STRATEGY]}       | ${0}             | ${'Start merge train'}
      ${[MT_MERGE_STRATEGY]}       | ${1}             | ${'Add to merge train'}
      ${[MTWPS_MERGE_STRATEGY]}    | ${0}             | ${'Start merge train when pipeline succeeds'}
      ${[MTWPS_MERGE_STRATEGY]}    | ${1}             | ${'Add to merge train when pipeline succeeds'}
    `(
      'displays $expectedText with merge strategy $availableAutoMergeStrategies and merge train count $mergeTrainsCount',
      ({ availableAutoMergeStrategies, mergeTrainsCount, expectedText }) => {
        createComponent({ availableAutoMergeStrategies, mergeTrainsCount });

        expect(findMergeButton().text()).toBe(expectedText);
      },
    );

    it('displays "Merge in progress"', () => {
      createComponent({}, shallowMountExtended, { isMergingImmediately: true });

      expect(findMergeButton().text()).toBe('Merge in progress');
    });
  });

  describe('shouldRenderMergeTrainHelperIcon', () => {
    it('should render the helper icon if MTWPS is available and the user has not yet pressed the MTWPS button', () => {
      createComponent({
        onlyAllowMergeIfPipelineSucceeds: true,
        availableAutoMergeStrategies: [MTWPS_MERGE_STRATEGY],
        autoMergeEnabled: false,
      });

      expect(findMergeTrainHelperIcon().exists()).toBe(true);
    });
  });

  describe('merge train helper icon', () => {
    it('does not render the merge train helper icon if the MTWPS strategy is not available', () => {
      createComponent({
        availableAutoMergeStrategies: [MT_MERGE_STRATEGY],
        headPipeline: activePipeline,
      });

      expect(findMergeTrainHelperIcon().exists()).toBe(false);
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
        createComponent(
          {
            availableAutoMergeStrategies: [mergeStrategy],
            headPipeline: {
              id: 'gid://gitlab/Pipeline/1',
              path: 'path/to/pipeline',
              status: isPipelineFailed ? 'FAILED' : 'PASSED',
            },
          },
          mountExtended,
        );
        const modalConfirmation = findMergeTrainFailedPipelineConfirmationDialog();

        await findMergeButton().vm.$emit('click');

        expect(modalConfirmation.props('visible')).toBe(isVisible);
      },
    );
  });

  describe('merge immediately warning dialog', () => {
    const clickMergeImmediately = async () => {
      expect(findMergeImmediatelyConfirmationDialog().exists()).toBe(true);

      findMergeImmediatelyDropdown().vm.$emit('show');
      await nextTick();

      findMergeImmediatelyButton().vm.$emit('click');

      await nextTick();
    };

    it('should show a warning dialog asking for confirmation if the user is trying to skip the merge train', async () => {
      createComponent({ availableAutoMergeStrategies: [MT_MERGE_STRATEGY] });

      await clickMergeImmediately();

      expect(showMock).toHaveBeenCalled();

      expect(findMergeTrainFailedPipelineConfirmationDialog().props('visible')).toBe(false);
      expect(findMergeButton().text()).toBe('Start merge train');
      expect(mr.transitionStateMachine).toHaveBeenCalledTimes(0);
    });

    it('should perform the merge when the user confirms their intent to merge immediately', async () => {
      createComponent({ availableAutoMergeStrategies: [MT_MERGE_STRATEGY] });

      await clickMergeImmediately();

      findMergeImmediatelyConfirmationDialog().vm.$emit('mergeImmediately');

      await nextTick();

      expect(findMergeTrainFailedPipelineConfirmationDialog().props('visible')).toBe(false);
      expect(findMergeButton().text()).toBe('Merge in progress');
      expect(mr.transitionStateMachine).toHaveBeenCalledWith({ transition: 'start-merge' });
    });

    it('should not ask for confirmation in non-merge train scenarios', async () => {
      createComponent({
        headPipeline: { id: 'gid://gitlab/Pipeline/1', path: 'path/to/pipeline', active: true },
        onlyAllowMergeIfPipelineSucceeds: false,
      });

      await clickMergeImmediately();

      expect(showMock).not.toHaveBeenCalled();
      expect(findMergeButton().text()).toBe('Merge in progress');
      expect(findMergeTrainFailedPipelineConfirmationDialog().props('visible')).toBe(false);
      expect(mr.transitionStateMachine).toHaveBeenCalled();
    });
  });

  describe('Merge train text', () => {
    describe('pipeline failed', () => {
      beforeEach(() => {
        createComponent({
          isPipelineFailed: true,
          availableAutoMergeStrategies: [MT_MERGE_STRATEGY],
          hasCI: true,
          onlyAllowMergeIfPipelineSucceeds: false,
        });
      });

      it('merge button text should contain ellipsis', () => {
        expect(findMergeButton().text()).toBe(MERGE_TRAIN_BUTTON_TEXT.failed);
      });
    });

    describe('pipeline passed', () => {
      beforeEach(() => {
        createComponent({
          availableAutoMergeStrategies: [MT_MERGE_STRATEGY],
          hasCI: true,
          onlyAllowMergeIfPipelineSucceeds: false,
          headPipeline: {
            id: 'gid://gitlab/Pipeline/1',
            path: 'path/to/pipeline',
            status: 'passed',
          },
        });
      });

      it('merge button text should not contain ellipsis', () => {
        expect(findMergeButton().text()).toBe(MERGE_TRAIN_BUTTON_TEXT.passed);
      });
    });
  });

  describe('Merge button text with auto_merge_labels_mr_widget feature flag turned on', () => {
    beforeEach(() => {
      window.gon = { features: { autoMergeLabelsMrWidget: true } };
    });

    it.each`
      availableAutoMergeStrategies | mergeTrainsCount | expectedText
      ${[]}                        | ${0}             | ${'Merge'}
      ${[MWPS_MERGE_STRATEGY]}     | ${0}             | ${'Set to auto-merge'}
      ${[MT_MERGE_STRATEGY]}       | ${0}             | ${'Merge'}
      ${[MT_MERGE_STRATEGY]}       | ${1}             | ${'Merge'}
      ${[MTWPS_MERGE_STRATEGY]}    | ${0}             | ${'Set to auto-merge'}
      ${[MTWPS_MERGE_STRATEGY]}    | ${1}             | ${'Set to auto-merge'}
    `(
      'displays $expectedText with merge strategy $availableAutoMergeStrategies and merge train count $mergeTrainsCount',
      ({ availableAutoMergeStrategies, mergeTrainsCount, expectedText }) => {
        createComponent({ availableAutoMergeStrategies, mergeTrainsCount });

        expect(findMergeButton().text()).toBe(expectedText);
      },
    );

    it('displays "Merge in progress"', () => {
      createComponent({}, shallowMountExtended, { isMergingImmediately: true });

      expect(findMergeButton().text()).toBe('Merge in progress');
    });
  });
});
