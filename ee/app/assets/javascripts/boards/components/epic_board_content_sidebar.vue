<script>
import { GlDrawer } from '@gitlab/ui';
import { MountingPortal } from 'portal-vue';
import { mapState, mapActions, mapGetters } from 'vuex';
import SidebarAncestorsWidget from 'ee_component/sidebar/components/ancestors_tree/sidebar_ancestors_widget.vue';
import BoardSidebarLabelsSelect from '~/boards/components/sidebar/board_sidebar_labels_select.vue';
import BoardSidebarTitle from '~/boards/components/sidebar/board_sidebar_title.vue';
import { ISSUABLE } from '~/boards/constants';
import SidebarConfidentialityWidget from '~/sidebar/components/confidential/sidebar_confidentiality_widget.vue';
import SidebarDateWidget from '~/sidebar/components/date/sidebar_date_widget.vue';
import SidebarParticipantsWidget from '~/sidebar/components/participants/sidebar_participants_widget.vue';
import SidebarSubscriptionsWidget from '~/sidebar/components/subscriptions/sidebar_subscriptions_widget.vue';
import SidebarTodoWidget from '~/sidebar/components/todo_toggle/sidebar_todo_widget.vue';

export default {
  components: {
    GlDrawer,
    SidebarTodoWidget,
    BoardSidebarLabelsSelect,
    BoardSidebarTitle,
    SidebarConfidentialityWidget,
    SidebarDateWidget,
    SidebarParticipantsWidget,
    SidebarSubscriptionsWidget,
    SidebarAncestorsWidget,
    MountingPortal,
  },
  inheritAttrs: false,
  computed: {
    ...mapGetters(['isSidebarOpen', 'activeBoardItem']),
    ...mapState(['sidebarType', 'issuableType']),
    isIssuableSidebar() {
      return this.sidebarType === ISSUABLE;
    },
    showSidebar() {
      return this.isIssuableSidebar && this.isSidebarOpen;
    },
    fullPath() {
      return this.activeBoardItem?.referencePath?.split('&')[0] || '';
    },
  },
  methods: {
    ...mapActions(['toggleBoardItem', 'setActiveItemConfidential', 'setActiveItemSubscribed']),
    handleClose() {
      this.toggleBoardItem({ boardItem: this.activeBoardItem, sidebarType: this.sidebarType });
    },
  },
};
</script>

<template>
  <mounting-portal mount-to="#js-right-sidebar-portal" name="epic-board-sidebar" append>
    <gl-drawer
      v-if="showSidebar"
      v-bind="$attrs"
      class="boards-sidebar gl-absolute"
      :open="isSidebarOpen"
      @close="handleClose"
    >
      <template #title>
        <h2 class="gl-my-0 gl-font-size-h2 gl-line-height-24">{{ __('Epic details') }}</h2>
      </template>
      <template #header>
        <sidebar-todo-widget
          class="gl-mt-3"
          :issuable-id="activeBoardItem.fullId"
          :issuable-iid="activeBoardItem.iid"
          :full-path="fullPath"
          :issuable-type="issuableType"
        />
      </template>
      <template #default>
        <board-sidebar-title data-testid="sidebar-title" />
        <sidebar-date-widget
          :iid="activeBoardItem.iid"
          :full-path="fullPath"
          date-type="startDate"
          :issuable-type="issuableType"
          :can-inherit="true"
        />
        <sidebar-date-widget
          :iid="activeBoardItem.iid"
          :full-path="fullPath"
          date-type="dueDate"
          :issuable-type="issuableType"
          :can-inherit="true"
        />
        <board-sidebar-labels-select class="labels" />
        <sidebar-confidentiality-widget
          :iid="activeBoardItem.iid"
          :full-path="fullPath"
          :issuable-type="issuableType"
          @confidentialityUpdated="setActiveItemConfidential($event)"
        />
        <sidebar-ancestors-widget
          :iid="activeBoardItem.iid"
          :full-path="fullPath"
          issuable-type="epic"
        />
        <sidebar-participants-widget
          :iid="activeBoardItem.iid"
          :full-path="fullPath"
          issuable-type="epic"
        />
        <sidebar-subscriptions-widget
          :iid="activeBoardItem.iid"
          :full-path="fullPath"
          :issuable-type="issuableType"
        />
      </template>
    </gl-drawer>
  </mounting-portal>
</template>
