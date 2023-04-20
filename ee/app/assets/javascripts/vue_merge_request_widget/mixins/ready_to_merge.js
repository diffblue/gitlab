import { isNumber, isString } from 'lodash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { helpPagePath } from '~/helpers/help_page_helper';
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

const MERGE_WHEN_PIPELINE_SUCCEEDS_HELP = helpPagePath(
  '/user/project/merge_requests/merge_when_pipeline_succeeds.html',
);
const MERGE_TRAINS_HELP = helpPagePath('ci/pipelines/merge_trains.html');

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
    autoMergeTextLegacy() {
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
    autoMergeText() {
      if (this.preferredAutoMergeStrategy === MT_MERGE_STRATEGY) {
        return __('Merge');
      }

      return __('Set to auto-merge');
    },
    autoMergeHelperText() {
      if (this.preferredAutoMergeStrategy === MTWPS_MERGE_STRATEGY) {
        return __('Add to merge train when pipeline succeeds');
      }
      if (this.preferredAutoMergeStrategy === MT_MERGE_STRATEGY) {
        return __('Add to merge train');
      }

      return __('Merge when pipeline succeeds');
    },
    autoMergePopoverSettings() {
      if (
        this.preferredAutoMergeStrategy === MT_MERGE_STRATEGY ||
        this.preferredAutoMergeStrategy === MTWPS_MERGE_STRATEGY
      ) {
        return {
          helpLink: MERGE_TRAINS_HELP,
          bodyText: __(
            'A %{linkStart}merge train%{linkEnd} is a queued list of merge requests, each waiting to be merged into the target branch.',
          ),
          title: __('Merge trains'),
        };
      }

      return {
        helpLink: MERGE_WHEN_PIPELINE_SUCCEEDS_HELP,
        bodyText: __(
          'When the pipeline for this merge request succeeds, it will %{linkStart}automatically merge%{linkEnd}.',
        ),
        title: __('Merge when pipeline succeeds'),
      };
    },
    pipelineId() {
      return getIdFromGraphQLId(this.pipeline.id);
    },
    shouldRenderMergeTrainHelperIcon() {
      return (
        this.pipeline &&
        isNumber(getIdFromGraphQLId(this.pipeline.id)) &&
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
