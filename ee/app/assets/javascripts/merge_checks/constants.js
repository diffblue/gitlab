import { s__ } from '~/locale';

export const I18N = {
  pipelineMustSucceed: {
    label: s__('MergeChecks|Pipelines must succeed'),
    help: s__(
      "MergeChecks|Merge requests can't be merged if the latest pipeline did not succeed or is still running.",
    ),
  },
  allowMergeOnSkipped: {
    label: s__('MergeChecks|Skipped pipelines are considered successful'),
    help: s__('MergeChecks|Introduces the risk of merging changes that do not pass the pipeline.'),
  },
  onlyMergeWhenAllResolvedLabel: s__('MergeChecks|All threads must be resolved'),
  lockedText: s__(
    'MergeChecks|This setting is configured in group %{groupName} and can only be changed in the group settings by an administrator or group owner.',
  ),
  lockedUponPipelineMustSucceed: s__('MergeChecks|Enable "Pipelines must succeed" first.'),
};
