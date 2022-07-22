<script>
import { GlAlert, GlButton, GlLoadingIcon, GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
import { createAlert } from '~/flash';
import {
  ACTIVE_STREAM,
  ADD_STREAM,
  ADD_STREAM_MESSAGE,
  AUDIT_STREAMS_NETWORK_ERRORS,
  DELETE_STREAM_MESSAGE,
  STREAM_COUNT_ICON_ALT,
  UPDATE_STREAM_MESSAGE,
} from '../constants';
import externalDestinationsQuery from '../graphql/get_external_destinations.query.graphql';
import StreamEmptyState from './stream/stream_empty_state.vue';
import StreamDestinationEditor from './stream/stream_destination_editor.vue';
import StreamItem from './stream/stream_item.vue';

const { FETCHING_ERROR } = AUDIT_STREAMS_NETWORK_ERRORS;
export default {
  components: {
    GlAlert,
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
      showEditor: false,
      successMessage: null,
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
      await this.refreshDestinations();
      this.setEditorVisibility(false);
      this.successMessage = ADD_STREAM_MESSAGE;
    },
    async onUpdatedDestination() {
      await this.refreshDestinations();
      this.setEditorVisibility(false);
      this.successMessage = UPDATE_STREAM_MESSAGE;
    },
    async onDeletedDestination() {
      await this.refreshDestinations();
      this.successMessage = DELETE_STREAM_MESSAGE;
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

        this.clearSuccessMessage();
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
  <stream-empty-state v-else-if="shouldShowEmptyMode" @add="setEditorVisibility(true)" />
  <div v-else>
    <gl-alert
      v-if="successMessage"
      :dismissible="true"
      class="gl-mb-5"
      variant="success"
      @dismiss="clearSuccessMessage"
    >
      {{ successMessage }}
    </gl-alert>
    <div v-if="destinationsCount" class="gl-display-flex gl-align-items-center gl-pl-5 gl-py-3">
      <img
        :alt="$options.i18n.STREAM_COUNT_ICON_ALT"
        :src="streamsIconSvgPath"
        class="gl-mr-2 gl-h-5 gl-w-5"
      />
      <span class="gl-mr-4">{{ destinationsCount }}</span>
      <gl-button
        :aria-label="$options.i18n.ADD_STREAM"
        icon="plus"
        @click="setEditorVisibility(true)"
      />
    </div>
    <div v-if="showEditor" class="gl-p-6 gl-border gl-rounded-base">
      <stream-destination-editor
        @added="onAddedDestination"
        @error="clearSuccessMessage"
        @cancel="setEditorVisibility(false)"
      />
    </div>
    <div v-if="destinationsCount" class="gl-p-4">
      <label class="gl-mb-3">{{ $options.i18n.ACTIVE_STREAM }}</label>
      <ul class="content-list bordered-box gl-bg-white">
        <stream-item
          v-for="item in externalAuditEventDestinations"
          :key="item.id"
          :item="item"
          @deleted="onDeletedDestination"
          @updated="onUpdatedDestination"
          @error="clearSuccessMessage"
        />
      </ul>
    </div>
  </div>
</template>
