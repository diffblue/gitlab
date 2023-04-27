<script>
import { GlAlert, GlButton, GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import {
  ADD_STREAM,
  ADD_STREAM_MESSAGE,
  AUDIT_STREAMS_NETWORK_ERRORS,
  DELETE_STREAM_MESSAGE,
  UPDATE_STREAM_MESSAGE,
  streamsLabel,
} from '../constants';
import { removeAuditEventsStreamingDestination } from '../graphql/cache_update';
import externalDestinationsQuery from '../graphql/queries/get_external_destinations.query.graphql';
import StreamEmptyState from './stream/stream_empty_state.vue';
import StreamDestinationEditor from './stream/stream_destination_editor.vue';
import StreamItem from './stream/stream_item.vue';

const { FETCHING_ERROR } = AUDIT_STREAMS_NETWORK_ERRORS;
export default {
  components: {
    GlAlert,
    GlButton,
    GlLoadingIcon,
    GlIcon,
    StreamDestinationEditor,
    StreamEmptyState,
    StreamItem,
  },
  inject: ['groupPath'],
  data() {
    return {
      externalAuditEventDestinations: null,
      showEditor: false,
      successMessage: null,
      groupEventFilters: [],
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.externalAuditEventDestinations.loading;
    },
    shouldShowEmptyMode() {
      return !this.destinationsCount && !this.showEditor;
    },
    destinationsCount() {
      return this.externalAuditEventDestinations?.length ?? 0;
    },
  },
  methods: {
    setEditorVisibility(state) {
      this.showEditor = state;
    },
    clearSuccessMessage() {
      this.successMessage = null;
    },
    refreshDestinations() {
      return this.$apollo.queries.externalAuditEventDestinations.refetch();
    },
    async onAddedDestination() {
      this.setEditorVisibility(false);
      this.successMessage = ADD_STREAM_MESSAGE;
    },
    async onUpdatedDestination() {
      this.setEditorVisibility(false);
      this.successMessage = UPDATE_STREAM_MESSAGE;
    },
    async onDeletedDestination(id) {
      removeAuditEventsStreamingDestination({
        store: this.$apollo.provider.defaultClient,
        fullPath: this.groupPath,
        destinationId: id,
      });

      if (this.destinationsCount) {
        this.successMessage = DELETE_STREAM_MESSAGE;
      }
    },
    setGroupEventFilters(nodes) {
      const filters = [];
      nodes.forEach((node) => {
        filters.push(...node.eventTypeFilters);
      });
      this.groupEventFilters = [...new Set(filters)];
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
        this.setGroupEventFilters(data.group.externalAuditEventDestinations.nodes);
        return data.group.externalAuditEventDestinations.nodes;
      },
      error() {
        createAlert({
          message: FETCHING_ERROR,
        });

        this.clearSuccessMessage();
      },
    },
  },
  i18n: {
    ADD_STREAM,
    FETCHING_ERROR,
    streamsLabel,
  },
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" size="lg" />
  <stream-empty-state v-else-if="shouldShowEmptyMode" @add="setEditorVisibility(true)" />
  <div v-else>
    <gl-alert
      v-if="successMessage"
      :dismissible="true"
      class="gl-mb-4"
      variant="success"
      @dismiss="clearSuccessMessage"
    >
      {{ successMessage }}
    </gl-alert>
    <div class="gl-display-flex gl-justify-content-space-between gl-align-items-center gl-mb-4">
      <label class="gl-m-0">
        <gl-icon name="live-stream" />
        {{ $options.i18n.streamsLabel(destinationsCount) }}
      </label>
      <gl-button variant="confirm" @click="setEditorVisibility(true)">
        {{ $options.i18n.ADD_STREAM }}
      </gl-button>
    </div>
    <div v-if="showEditor" class="gl-mb-4 gl-p-4 gl-border gl-rounded-base">
      <stream-destination-editor
        :group-event-filters="groupEventFilters"
        @added="onAddedDestination"
        @error="clearSuccessMessage"
        @cancel="setEditorVisibility(false)"
      />
    </div>
    <ul class="content-list gl-border gl-rounded-base gl-bg-white">
      <stream-item
        v-for="item in externalAuditEventDestinations"
        :key="item.id"
        :item="item"
        :group-event-filters="groupEventFilters"
        @deleted="onDeletedDestination(item.id)"
        @updated="onUpdatedDestination"
        @error="clearSuccessMessage"
      />
    </ul>
  </div>
</template>
