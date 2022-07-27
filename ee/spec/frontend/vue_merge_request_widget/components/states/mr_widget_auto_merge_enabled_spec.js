import { shallowMount } from '@vue/test-utils';
import MRWidgetAutoMergeEnabled from '~/vue_merge_request_widget/components/states/mr_widget_auto_merge_enabled.vue';
import {
  MWPS_MERGE_STRATEGY,
  MT_MERGE_STRATEGY,
  MTWPS_MERGE_STRATEGY,
} from '~/vue_merge_request_widget/constants';

describe('MRWidgetAutoMergeEnabled', () => {
  let wrapper;
  let vm;

  const service = {
    merge: () => {},
    poll: () => {},
  };

  const getStatusText = () => wrapper.find('[data-testid="statusText"]').attributes('message');

  const mr = {
    shouldRemoveSourceBranch: false,
    canRemoveSourceBranch: true,
    canCancelAutomaticMerge: true,
    mergeUserId: 1,
    currentUserId: 1,
    setToAutoMergeBy: {},
    sha: '1EA2EZ34',
    targetBranchPath: '/foo/bar',
    targetBranch: 'foo',
    autoMergeStrategy: MTWPS_MERGE_STRATEGY,
  };

  const factory = (mrUpdates = {}) => {
    wrapper = shallowMount(MRWidgetAutoMergeEnabled, {
      propsData: {
        mr: { ...mr, ...mrUpdates },
        service,
      },
    });

    ({ vm } = wrapper);
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('computed', () => {
    describe('status', () => {
      it('should return "to start a merge train..." if MTWPS is selected and there is no existing merge train', () => {
        factory({
          autoMergeStrategy: MTWPS_MERGE_STRATEGY,
          mergeTrainsCount: 0,
        });

        expect(getStatusText()).toBe(
          'Set by %{merge_author} to start a merge train when the pipeline succeeds',
        );
      });

      it('should return "to be added to the merge train..." if MTWPS is selected and there is an existing merge train', () => {
        factory({
          autoMergeStrategy: MTWPS_MERGE_STRATEGY,
          mergeTrainsCount: 1,
        });

        expect(getStatusText()).toBe(
          'Set by %{merge_author} to be added to the merge train when the pipeline succeeds',
        );
      });

      it('should return "to be merged automatically..." if MWPS is selected', () => {
        factory({ autoMergeStrategy: MWPS_MERGE_STRATEGY });

        expect(getStatusText()).toBe(
          'Set by %{merge_author} to be merged automatically when the pipeline succeeds',
        );
      });
    });

    describe('cancelButtonText', () => {
      it('should return "Cancel start merge train" if MTWPS is selected', () => {
        factory({ autoMergeStrategy: MTWPS_MERGE_STRATEGY });

        expect(vm.cancelButtonText).toBe('Cancel auto-merge');
      });

      it('should return "Remove from merge train" if the pipeline has been added to the merge train', () => {
        factory({ autoMergeStrategy: MT_MERGE_STRATEGY });

        expect(vm.cancelButtonText).toBe('Remove from merge train');
      });

      it('should return "Cancel" if MWPS is selected', () => {
        factory({ autoMergeStrategy: MWPS_MERGE_STRATEGY });

        expect(vm.cancelButtonText).toBe('Cancel auto-merge');
      });
    });
  });

  describe('template', () => {
    it('should render the cancel button as "Cancel" if MTWPS is selected', () => {
      factory({ autoMergeStrategy: MTWPS_MERGE_STRATEGY });

      const cancelButtonText = wrapper.find('.js-cancel-auto-merge').text();

      expect(cancelButtonText).toBe('Cancel auto-merge');
    });
  });

  it('should render the cancel button as "Remove from merge train" if the pipeline has been added to the merge train', () => {
    factory({ autoMergeStrategy: MT_MERGE_STRATEGY });

    const cancelButtonText = wrapper.find('.js-cancel-auto-merge').text();

    expect(cancelButtonText).toBe('Remove from merge train');
  });
});
