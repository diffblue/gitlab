<script>
import { GlIcon, GlLink, GlPopover } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'MergeTrainHelperIcon',
  components: {
    GlIcon,
    GlLink,
    GlPopover,
  },
  props: {
    mergeTrainWhenPipelineSucceedsDocsPath: {
      type: String,
      required: true,
    },
  },

  i18n: {
    popoverTitle: s__('mrWidget|What is a merge train?'),
    popoverContent: s__(
      'mrWidget|A merge train is a queued list of merge requests waiting to be merged into the target branch. The changes in each merge request are combined with the changes in earlier merge requests and tested before merge.',
    ),
    moreInfo: s__('mrWidget|More information'),
    learnMore: s__('mrWidget|Learn more'),
  },
};
</script>

<template>
  <div id="merge-train-help-container" data-testid="merge-train-helper-icon">
    <gl-icon
      id="merge-train-help"
      name="question-o"
      class="gl-text-blue-600"
      :aria-label="$options.i18n.moreInfo"
    />
    <gl-popover
      target="merge-train-help"
      container="merge-train-help-container"
      placement="top"
      :title="$options.i18n.popoverTitle"
      triggers="hover focus"
    >
      <p>{{ $options.i18n.popoverContent }}</p>
      <gl-link
        class="gl-mt-3"
        :href="mergeTrainWhenPipelineSucceedsDocsPath"
        target="_blank"
        rel="noopener noreferrer"
        data-testid="documentation-link"
      >
        {{ $options.i18n.learnMore }}
      </gl-link>
    </gl-popover>
  </div>
</template>
