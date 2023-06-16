<script>
import { GlIcon, GlLink, GlPopover } from '@gitlab/ui';
import { joinPaths } from '~/lib/utils/url_utility';
import { METRIC_TOOLTIPS } from '~/analytics/shared/constants';
import { s__ } from '~/locale';
import { TABLE_METRICS } from '../constants';

export default {
  name: 'MetricTableCell',
  components: {
    GlIcon,
    GlLink,
    GlPopover,
  },
  props: {
    identifier: {
      type: String,
      required: true,
    },
    requestPath: {
      type: String,
      required: true,
    },
    isProject: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    metric() {
      return TABLE_METRICS[this.identifier];
    },
    tooltip() {
      return METRIC_TOOLTIPS[this.identifier];
    },
    link() {
      const { groupLink, projectLink } = this.tooltip;
      return joinPaths(
        '/',
        gon.relative_url_root,
        this.requestPath,
        this.isProject ? projectLink : groupLink,
      );
    },
    popoverTarget() {
      return `${this.requestPath}__${this.identifier}`.replace('/', '_');
    },
  },
  i18n: {
    docsLabel: s__('DORA4Metrics|Go to docs'),
  },
};
</script>
<template>
  <div>
    <gl-link :href="link" data-testid="metric_label">{{ metric.label }}</gl-link>
    <gl-icon
      :id="popoverTarget"
      data-testid="info_icon"
      name="information-o"
      class="gl-text-blue-600"
    />
    <gl-popover :target="popoverTarget" :title="metric.label" show-close-button>
      {{ tooltip.description }}
      <gl-link :href="tooltip.docsLink" class="gl-display-block gl-mt-2 gl-font-sm" target="_blank">
        {{ $options.i18n.docsLabel }}
        <gl-icon name="external-link" class="gl-vertical-align-middle" />
      </gl-link>
    </gl-popover>
  </div>
</template>
