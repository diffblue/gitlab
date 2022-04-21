<script>
import { GlAlert } from '@gitlab/ui';
import { sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  AGGREGATING_DATA_WARNING_TITLE,
  AGGREGATING_DATA_WARNING_MESSAGE,
  AGGREGATING_DATA_WARNING_NEXT_UPDATE,
  AGGREGATING_DATA_PRIMARY_ACTION_TEXT,
  AGGREGATING_DATA_SECONDARY_ACTION_TEXT,
} from '../constants';

export default {
  name: 'ValueStreamAggregatingWarning',
  components: {
    GlAlert,
  },
  props: {
    valueStreamTitle: {
      type: String,
      required: true,
    },
  },
  computed: {
    message() {
      return sprintf(AGGREGATING_DATA_WARNING_MESSAGE, { name: this.valueStreamTitle });
    },
  },
  i18n: {
    title: AGGREGATING_DATA_WARNING_TITLE,
    nextUpdate: AGGREGATING_DATA_WARNING_NEXT_UPDATE,
    primaryText: AGGREGATING_DATA_PRIMARY_ACTION_TEXT,
    secondaryText: AGGREGATING_DATA_SECONDARY_ACTION_TEXT,
  },
  docsPath: helpPagePath('user/group/value_stream_analytics/index', {
    anchor: 'create-a-value-stream',
  }),
};
</script>
<template>
  <gl-alert
    :title="$options.i18n.title"
    :dismissible="false"
    :primary-button-text="$options.i18n.primaryText"
    :secondary-button-text="$options.i18n.secondaryText"
    :secondary-button-link="$options.docsPath"
    @primaryAction="$emit('reload')"
  >
    <p>{{ message }}</p>
    <p>{{ $options.i18n.nextUpdate }}</p>
  </gl-alert>
</template>
