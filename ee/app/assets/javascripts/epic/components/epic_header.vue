<script>
// eslint-disable-next-line no-restricted-imports
import { mapState, mapGetters, mapActions } from 'vuex';
import { EVENT_ISSUABLE_VUE_APP_CHANGE } from '~/issuable/constants';
import { STATUS_CLOSED, STATUS_OPEN, TYPE_EPIC, WORKSPACE_GROUP } from '~/issues/constants';
import IssuableHeader from '~/vue_shared/issuable/show/components/issuable_header.vue';
import epicUtils from '../utils/epic_utils';

export default {
  TYPE_EPIC,
  WORKSPACE_GROUP,
  components: {
    IssuableHeader,
  },
  props: {
    formattedAuthor: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState(['sidebarCollapsed', 'author', 'created', 'confidential', 'state']),
    ...mapGetters(['isEpicOpen']),
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
    class="gl-p-0 gl-mb-6 gl-mt-2 gl-sm-mt-0"
    :author="formattedAuthor"
    :confidential="confidential"
    :created-at="created"
    :issuable-state="state"
    :issuable-type="$options.TYPE_EPIC"
    :status-icon="statusIcon"
    :workspace-type="$options.WORKSPACE_GROUP"
    @toggle="toggleSidebar({ sidebarCollapsed })"
  />
</template>
