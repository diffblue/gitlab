<script>
import { GlLink, GlButton } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { __, s__ } from '~/locale';
import { ACTION_TYPES } from '../constants';
import GeoReplicableStatus from './geo_replicable_status.vue';
import GeoReplicableTimeAgo from './geo_replicable_time_ago.vue';

export default {
  name: 'GeoReplicableItem',
  i18n: {
    unknown: __('Unknown'),
    nA: __('Not applicable.'),
    resync: s__('Geo|Resync'),
    lastVerified: s__('Geo|Last time verified'),
  },
  components: {
    GlLink,
    GlButton,
    GeoReplicableTimeAgo,
    GeoReplicableStatus,
  },
  props: {
    name: {
      type: String,
      required: true,
    },
    projectId: {
      type: Number,
      required: false,
      default: null,
    },
    syncStatus: {
      type: String,
      required: false,
      default: '',
    },
    lastSynced: {
      type: String,
      required: false,
      default: '',
    },
    lastVerified: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    ...mapState(['verificationEnabled']),
    hasProject() {
      return Boolean(this.projectId);
    },
    timeAgoArray() {
      return [
        {
          label: capitalizeFirstCharacter(this.syncStatus),
          dateString: this.lastSynced,
          defaultText: this.$options.i18n.unknown,
        },
        {
          label: this.$options.i18n.lastVerified,
          dateString: this.lastVerified,
          defaultText: this.verificationEnabled
            ? this.$options.i18n.unknown
            : this.$options.i18n.nA,
        },
      ];
    },
  },
  methods: {
    ...mapActions(['initiateReplicableSync']),
  },
  actionTypes: ACTION_TYPES,
};
</script>

<template>
  <div class="gl-border-b gl-p-5">
    <div
      class="geo-replicable-item-grid gl-display-grid gl-align-items-center gl-pb-4"
      data-testid="replicable-item-header"
    >
      <geo-replicable-status :status="syncStatus" />
      <template v-if="hasProject">
        <gl-link class="gl-font-weight-bold gl-pr-3" :href="`/${name}`" target="_blank">{{
          name
        }}</gl-link>
        <gl-button
          class="gl-ml-auto"
          size="small"
          @click="initiateReplicableSync({ projectId, name, action: $options.actionTypes.RESYNC })"
          >{{ $options.i18n.resync }}</gl-button
        >
      </template>
      <template v-else>
        <span class="gl-font-weight-bold">{{ name }}</span>
      </template>
    </div>
    <div class="gl-display-flex gl-align-items-center gl-flex-wrap">
      <geo-replicable-time-ago
        v-for="(timeAgo, index) in timeAgoArray"
        :key="index"
        :label="timeAgo.label"
        :date-string="timeAgo.dateString"
        :default-text="timeAgo.defaultText"
        :show-divider="index !== timeAgoArray.length - 1"
      />
    </div>
  </div>
</template>
