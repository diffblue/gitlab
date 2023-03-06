<script>
import { GlIcon, GlLink, GlPopover } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';

export default {
  name: 'MergeTrainHelperIcon',
  components: {
    GlIcon,
    GlLink,
    GlPopover,
  },
  i18n: {
    popoverTitle: s__('mrWidget|What is a merge train?'),
    popoverContent: s__(
      'mrWidget|A merge train is a queued list of merge requests waiting to be merged into the target branch. The changes in each merge request are combined with the changes in earlier merge requests and tested before merge.',
    ),
    moreInfo: s__('mrWidget|More information'),
    learnMore: s__('mrWidget|Learn more'),
  },
  popoverConstants: {
    target: 'merge-train-help',
    container: 'merge-train-help-container',
  },
  computed: {
    mergeTrainWhenPipelineSucceedsDocsPath() {
      return helpPagePath('ci/pipelines/merge_trains.md', {
        anchor: 'add-a-merge-request-to-a-merge-train',
      });
    },
  },
};
</script>

<template>
  <div :id="$options.popoverConstants.container">
    <gl-icon
      :id="$options.popoverConstants.target"
      name="question-o"
      class="gl-text-blue-600"
      :aria-label="$options.i18n.moreInfo"
      data-testid="merge-train-helper-icon"
    />
    <gl-popover
      :target="$options.popoverConstants.target"
      :container="$options.popoverConstants.container"
      placement="top"
      :title="$options.i18n.popoverTitle"
      triggers="hover focus"
    >
      <p data-testid="merge-train-helper-content">{{ $options.i18n.popoverContent }}</p>
      <gl-link
        class="gl-mt-3"
        :href="mergeTrainWhenPipelineSucceedsDocsPath"
        target="_blank"
        rel="noopener noreferrer"
      >
        {{ $options.i18n.learnMore }}
      </gl-link>
    </gl-popover>
  </div>
</template>
