<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import { EVENT_ISSUABLE_VUE_APP_CHANGE } from '~/issuable/constants';
import { STATUS_CLOSED, STATUS_OPEN, TYPE_EPIC, WORKSPACE_GROUP } from '~/issues/constants';
import IssuableHeader from '~/vue_shared/issuable/show/components/issuable_header.vue';
import epicUtils from '../utils/epic_utils';
import EpicHeaderActions from './epic_header_actions.vue';

export default {
  TYPE_EPIC,
  WORKSPACE_GROUP,
  components: {
    EpicHeaderActions,
    IssuableHeader,
  },
  computed: {
    ...mapState(['sidebarCollapsed', 'author', 'created', 'confidential', 'state']),
    ...mapGetters(['isEpicOpen']),
    formattedAuthor() {
      const { src, url, username } = this.author;
      return {
        ...this.author,
        avatarUrl: src,
        username: username.startsWith('@') ? username.substring(1) : username,
        webUrl: url,
      };
    },
    statusIcon() {
      return this.isEpicOpen ? 'epic' : 'epic-closed';
    },
  },
  mounted() {
    /**
     * This event is triggered from Notes app
     * when user clicks on `Close` button below
     * comment form.
     *
     * When event is triggered, we want to reflect Epic status change
     * across the UI so we directly call `requestEpicStatusChangeSuccess` action
     * to update store state.
     */
    epicUtils.bindDocumentEvent(EVENT_ISSUABLE_VUE_APP_CHANGE, (e, isClosed) => {
      const isEpicOpen = e.detail ? !e.detail.isClosed : !isClosed;
      this.requestEpicStatusChangeSuccess({
        state: isEpicOpen ? STATUS_OPEN : STATUS_CLOSED,
      });
    });
  },
  methods: {
    ...mapActions(['toggleSidebar', 'requestEpicStatusChangeSuccess']),
  },
};
</script>

<template>
  <issuable-header
    :author="formattedAuthor"
    :confidential="confidential"
    :created-at="created"
    :issuable-state="state"
    :issuable-type="$options.TYPE_EPIC"
    :status-icon="statusIcon"
    :workspace-type="$options.WORKSPACE_GROUP"
    @toggle="toggleSidebar({ sidebarCollapsed })"
  >
    <template #header-actions>
      <epic-header-actions />
    </template>
  </issuable-header>
</template>
