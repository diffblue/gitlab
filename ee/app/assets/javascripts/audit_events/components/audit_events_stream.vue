<script>
import { GlButton, GlLoadingIcon, GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
import { createAlert } from '~/flash';
import {
  ACTIVE_STREAM,
  ADD_STREAM,
  AUDIT_STREAMS_NETWORK_ERRORS,
  STREAM_COUNT_ICON_ALT,
} from '../constants';
import externalDestinationsQuery from '../graphql/get_external_destinations.query.graphql';
import StreamEmptyState from './stream/stream_empty_state.vue';
import StreamDestinationEditor from './stream/stream_destination_editor.vue';
import StreamItem from './stream/stream_item.vue';

const { FETCHING_ERROR } = AUDIT_STREAMS_NETWORK_ERRORS;
export default {
  components: {
    GlButton,
    GlLoadingIcon,
    StreamDestinationEditor,
    StreamEmptyState,
    StreamItem,
  },
  directives: {
    SafeHtml,
  },
  inject: ['groupPath', 'streamsIconSvgPath'],
  data() {
    return {
      externalAuditEventDestinations: null,
      isEditing: false,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.externalAuditEventDestinations.loading;
    },
    shouldShowEmptyMode() {
      return !this.destinationsCount && !this.isEditing;
    },
    destinationsCount() {
      return this.externalAuditEventDestinations?.length ?? 0;
    },
  },
  methods: {
    setEditMode(state) {
      this.isEditing = state;
    },
    refreshDestinations() {
      return this.$apollo.queries.externalAuditEventDestinations.refetch();
    },
    async onAddedDestination() {
      await this.refreshDestinations();
      this.setEditMode(false);
    },
  },
  apollo: {
    externalAuditEventDestinations: {
      query: externalDestinationsQuery,
      context: {
        isSingleRequest: true,
      },
      variables() {
        return {
          fullPath: this.groupPath,
        };
      },
      skip() {
        return !this.groupPath;
      },
      update(data) {
        return data.group.externalAuditEventDestinations.nodes;
      },
      error() {
        createAlert({
          message: FETCHING_ERROR,
        });
      },
    },
  },
  i18n: {
    ACTIVE_STREAM,
    ADD_STREAM,
    FETCHING_ERROR,
    STREAM_COUNT_ICON_ALT,
  },
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" size="lg" />
  <stream-empty-state v-else-if="shouldShowEmptyMode" @add="setEditMode(true)" />
  <div v-else>
    <div v-if="destinationsCount" class="gl-display-flex gl-align-items-center gl-pl-5 gl-py-3">
      <img
        :alt="$options.i18n.STREAM_COUNT_ICON_ALT"
        :src="streamsIconSvgPath"
        class="gl-mr-2 gl-h-5 gl-w-5"
      />
      <span class="gl-mr-4">{{ destinationsCount }}</span>
      <gl-button :aria-label="$options.i18n.ADD_STREAM" icon="plus" @click="setEditMode(true)" />
    </div>
    <div v-if="isEditing" class="gl-p-4">
      <stream-destination-editor @added="onAddedDestination" @cancel="setEditMode(false)" />
    </div>
    <div v-if="destinationsCount" class="gl-p-4">
      <label class="gl-mb-3">{{ $options.i18n.ACTIVE_STREAM }}</label>
      <ul class="content-list bordered-box gl-bg-white">
        <stream-item
          v-for="item in externalAuditEventDestinations"
          :key="item.id"
          :item="item"
          @delete="refreshDestinations"
        />
      </ul>
    </div>
  </div>
</template>
