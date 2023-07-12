<script>
import { v4 as uuidv4 } from 'uuid';
import { GlLabel, GlButton, GlPopover } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { isScopedLabel } from '~/lib/utils/common_utils';
import { joinPaths, mergeUrlParams } from '~/lib/utils/url_utility';

const MAX_PRIMARY_LABELS = 2;

export default {
  name: 'ComparisonChartLabels',
  components: {
    GlLabel,
    GlButton,
    GlPopover,
  },
  props: {
    labels: {
      type: Array,
      required: true,
    },
    webUrl: {
      type: String,
      required: true,
    },
  },
  computed: {
    // The labels visible outside the popover
    primaryLabels() {
      return this.labels.slice(0, MAX_PRIMARY_LABELS);
    },

    showMoreVisible() {
      return this.labels.length > MAX_PRIMARY_LABELS;
    },

    showMoreButtonText() {
      return sprintf(__('+ %{count} more'), { count: this.labels.length - MAX_PRIMARY_LABELS });
    },

    popoverTarget() {
      return uuidv4();
    },

    labelsPagePath() {
      return joinPaths(this.webUrl, '-', 'labels');
    },
  },
  methods: {
    isScoped(label) {
      return isScopedLabel(label);
    },
    labelTarget(name) {
      return mergeUrlParams({ search: name }, this.labelsPagePath);
    },
  },
  i18n: {
    filteredBy: s__('DORA4Metrics|Filtered by'),
    allLabels: s__('DORA4Metrics|All labels'),
  },
};
</script>
<template>
  <div>
    <span class="gl-font-sm gl-text-gray-900 gl-mr-2">{{ $options.i18n.filteredBy }}</span>
    <span data-testid="primary-labels">
      <gl-label
        v-for="label in primaryLabels"
        :key="label.id"
        class="gl-ml-2"
        :title="label.title"
        :background-color="label.color"
        :scoped="isScoped(label)"
        :target="labelTarget(label.title)"
        size="sm"
      />
    </span>

    <template v-if="showMoreVisible">
      <gl-button
        :id="popoverTarget"
        class="gl-ml-2 gl-text-decoration-none!"
        variant="link"
        size="small"
        button-text-classes="gl-text-secondary"
      >
        {{ showMoreButtonText }}
      </gl-button>
      <gl-popover :target="popoverTarget" :title="$options.i18n.allLabels" placement="bottom">
        <div class="gl-display-flex gl-flex-direction-column gl-gap-2">
          <div v-for="label in labels" :key="label.id">
            <gl-label
              :title="label.title"
              :background-color="label.color"
              :scoped="isScoped(label)"
              :target="labelTarget(label.title)"
              size="sm"
            />
          </div>
        </div>
      </gl-popover>
    </template>
  </div>
</template>
