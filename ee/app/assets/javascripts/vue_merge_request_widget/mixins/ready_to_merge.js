import { isNumber, isString } from 'lodash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __, s__ } from '~/locale';
import {
  MTWPS_MERGE_STRATEGY,
  MT_MERGE_STRATEGY,
  PIPELINE_FAILED_STATE,
} from '~/vue_merge_request_widget/constants';
import base from '~/vue_merge_request_widget/mixins/ready_to_merge';
import { MERGE_TRAIN_BUTTON_TEXT } from '~/vue_merge_request_widget/i18n';

export const MERGE_DISABLED_TEXT_UNAPPROVED = s__(
  'mrWidget|Merge blocked: all required approvals must be given.',
);
export const PIPELINE_MUST_SUCCEED_CONFLICT_TEXT = __(
  'A CI/CD pipeline must run and be successful before merge.',
);
export const MERGE_DISABLED_DEPENDENCIES_TEXT = __(
  'Merge blocked: all merge request dependencies must be merged.',
);

export default {
  computed: {
    isApprovalNeeded() {
      return this.mr.hasApprovalsAvailable ? !this.mr.isApproved : false;
    },
    isMergeButtonDisabled() {
      const { commitMessage } = this;
      return Boolean(
        !commitMessage.length ||
          !this.shouldShowMergeControls ||
          this.isMakingRequest ||
          this.isApprovalNeeded ||
          this.mr.preventMerge,
      );
    },
    hasBlockingMergeRequests() {
      return (
        (this.mr.blockingMergeRequests?.visible_merge_requests?.merged?.length || 0) !==
        (this.mr.blockingMergeRequests?.total_count || 0)
      );
    },
    shouldShowMergeControls() {
      if (this.glFeatures.restructuredMrWidget) {
        return this.restructuredWidgetShowMergeButtons;
      }

      if (this.hasBlockingMergeRequests) {
        return false;
      }

      return this.isMergeAllowed || this.isAutoMergeAvailable;
    },
    mergeDisabledText() {
      if (this.isApprovalNeeded) {
        return MERGE_DISABLED_TEXT_UNAPPROVED;
      } else if (this.hasBlockingMergeRequests) {
        return MERGE_DISABLED_DEPENDENCIES_TEXT;
      }

      return base.computed.mergeDisabledText.call(this);
    },
    pipelineMustSucceedConflictText() {
      return PIPELINE_MUST_SUCCEED_CONFLICT_TEXT;
    },
    autoMergeText() {
      if (this.preferredAutoMergeStrategy === MTWPS_MERGE_STRATEGY) {
        if (this.stateData.mergeTrainsCount === 0) {
          return __('Start merge train when pipeline succeeds');
        }
        return __('Add to merge train when pipeline succeeds');
      } else if (this.preferredAutoMergeStrategy === MT_MERGE_STRATEGY) {
        if (this.stateData.mergeTrainsCount === 0) {
          const pipelineFailed = this.status === PIPELINE_FAILED_STATE || this.isPipelineFailed;

          return pipelineFailed ? MERGE_TRAIN_BUTTON_TEXT.failed : MERGE_TRAIN_BUTTON_TEXT.passed;
        }
        return __('Add to merge train');
      }
      return __('Merge when pipeline succeeds');
    },
    pipelineId() {
      if (this.glFeatures.mergeRequestWidgetGraphql) {
        return getIdFromGraphQLId(this.pipeline.id);
      }

      return this.pipeline.id;
    },
    shouldRenderMergeTrainHelperIcon() {
      return (
        this.pipeline &&
        isNumber(this.pipelineId) &&
        isString(this.pipeline.path) &&
        this.preferredAutoMergeStrategy === MTWPS_MERGE_STRATEGY &&
        !this.stateData.autoMergeEnabled
      );
    },
    shouldShowMergeImmediatelyDropdown() {
      if (this.preferredAutoMergeStrategy === MT_MERGE_STRATEGY) {
        return true;
      }

      return this.isPipelineActive && !this.stateData.onlyAllowMergeIfPipelineSucceeds;
    },
    isMergeImmediatelyDangerous() {
      return [MT_MERGE_STRATEGY, MTWPS_MERGE_STRATEGY].includes(this.preferredAutoMergeStrategy);
    },
    showFailedPipelineModalMergeTrain() {
      const pipelineFailed = this.status === PIPELINE_FAILED_STATE || this.isPipelineFailed;
      const mergeStrateyMergeTrain = this.preferredAutoMergeStrategy === MT_MERGE_STRATEGY;

      return pipelineFailed && mergeStrateyMergeTrain;
    },
  },
  methods: {
    onStartMergeTrainConfirmation() {
      this.handleMergeButtonClick(this.isAutoMergeAvailable, false, true);
    },
  },
};
