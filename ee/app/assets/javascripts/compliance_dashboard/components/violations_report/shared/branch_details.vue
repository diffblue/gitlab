<script>
import { GlLink, GlSprintf, GlTooltipDirective, GlTruncate } from '@gitlab/ui';

import { __ } from '~/locale';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlLink,
    GlSprintf,
    GlTruncate,
  },
  props: {
    sourceBranch: {
      type: Object,
      required: true,
    },
    targetBranch: {
      type: Object,
      required: true,
    },
  },
  strings: {
    branchDetails: __('%{sourceBranch} into %{targetBranch}'),
  },
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-center">
    <gl-sprintf :message="$options.strings.branchDetails">
      <template #sourceBranch>
        <span class="gl-mr-2 gl-min-w-0">
          <gl-link v-if="sourceBranch.uri" :href="targetBranch.uri" data-testid="source-branch-uri">
            <gl-truncate
              v-gl-tooltip
              :title="sourceBranch.name"
              :text="sourceBranch.name"
              position="middle"
            />
          </gl-link>
          <gl-truncate
            v-else
            v-gl-tooltip
            :title="sourceBranch.name"
            :text="sourceBranch.name"
            position="middle"
          />
        </span>
      </template>
      <template #targetBranch>
        <span class="gl-ml-2 gl-min-w-0">
          <gl-link v-if="targetBranch.uri" :href="targetBranch.uri" data-testid="target-branch-uri">
            <gl-truncate
              v-gl-tooltip
              :title="targetBranch.name"
              :text="targetBranch.name"
              position="middle"
            />
          </gl-link>
          <gl-truncate
            v-else
            v-gl-tooltip
            :title="targetBranch.name"
            :text="targetBranch.name"
            position="middle"
          />
        </span>
      </template>
    </gl-sprintf>
  </div>
</template>
