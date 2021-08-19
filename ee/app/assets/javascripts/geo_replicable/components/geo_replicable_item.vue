<script>
import { GlLink, GlButton } from '@gitlab/ui';
import { mapActions } from 'vuex';
import { __ } from '~/locale';
import { ACTION_TYPES } from '../constants';
import GeoReplicableStatus from './geo_replicable_status.vue';
import GeoReplicableTimeAgo from './geo_replicable_time_ago.vue';

export default {
  name: 'GeoReplicableItem',
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
    lastChecked: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      timeAgoArray: [
        {
          label: __('Last successful sync'),
          dateString: this.lastSynced,
          defaultText: __('Never'),
        },
        {
          label: __('Last time verified'),
          dateString: this.lastVerified,
          defaultText: __('Not Implemented'),
        },
        {
          label: __('Last time checked'),
          dateString: this.lastChecked,
          defaultText: __('Not Implemented'),
        },
      ],
    };
  },
  computed: {
    hasProject() {
      return Boolean(this.projectId);
    },
  },
  methods: {
    ...mapActions(['initiateReplicableSync']),
  },
  actionTypes: ACTION_TYPES,
};
</script>

<template>
  <div class="card">
    <div v-if="hasProject" class="card-header d-flex align-center">
      <gl-link class="font-weight-bold" :href="`/${name}`" target="_blank">{{ name }}</gl-link>
      <div class="ml-auto">
        <gl-button
          size="small"
          @click="initiateReplicableSync({ projectId, name, action: $options.actionTypes.RESYNC })"
          >{{ __('Resync') }}</gl-button
        >
      </div>
    </div>
    <div v-else class="card-header">
      <span class="font-weight-bold">{{ name }}</span>
    </div>
    <div class="card-body">
      <div class="d-flex flex-column flex-md-row">
        <div class="flex-grow-1">
          <label class="text-muted">{{ __('Status') }}</label>
          <geo-replicable-status :status="syncStatus" />
        </div>
        <geo-replicable-time-ago
          v-for="(timeAgo, index) in timeAgoArray"
          :key="index"
          class="flex-grow-1"
          :label="timeAgo.label"
          :date-string="timeAgo.dateString"
          :default-text="timeAgo.defaultText"
        />
      </div>
    </div>
  </div>
</template>
