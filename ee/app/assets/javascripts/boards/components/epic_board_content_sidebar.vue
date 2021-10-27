<script>
import { GlDrawer } from '@gitlab/ui';
import { MountingPortal } from 'portal-vue';
import { mapState, mapActions, mapGetters } from 'vuex';
import SidebarAncestorsWidget from 'ee_component/sidebar/components/ancestors_tree/sidebar_ancestors_widget.vue';
import BoardSidebarLabelsSelect from '~/boards/components/sidebar/board_sidebar_labels_select.vue';
import BoardSidebarTitle from '~/boards/components/sidebar/board_sidebar_title.vue';
import { ISSUABLE } from '~/boards/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import SidebarConfidentialityWidget from '~/sidebar/components/confidential/sidebar_confidentiality_widget.vue';
import SidebarDateWidget from '~/sidebar/components/date/sidebar_date_widget.vue';
import SidebarParticipantsWidget from '~/sidebar/components/participants/sidebar_participants_widget.vue';
import SidebarSubscriptionsWidget from '~/sidebar/components/subscriptions/sidebar_subscriptions_widget.vue';
import SidebarTodoWidget from '~/sidebar/components/todo_toggle/sidebar_todo_widget.vue';
import SidebarLabelsWidget from '~/vue_shared/components/sidebar/labels_select_widget/labels_select_root.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: {
    GlDrawer,
    SidebarTodoWidget,
    BoardSidebarLabelsSelect,
    BoardSidebarTitle,
    SidebarLabelsWidget,
    SidebarConfidentialityWidget,
    SidebarDateWidget,
    SidebarParticipantsWidget,
    SidebarSubscriptionsWidget,
    SidebarAncestorsWidget,
    MountingPortal,
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['canUpdate', 'labelsFilterBasePath'],
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
    ...mapActions([
      'toggleBoardItem',
      'setActiveItemConfidential',
      'setActiveItemSubscribed',
      'setActiveBoardItemLabels',
    ]),
    handleClose() {
      this.toggleBoardItem({ boardItem: this.activeBoardItem, sidebarType: this.sidebarType });
    },
    handleUpdateSelectedLabels({ labels, id }) {
      this.setActiveBoardItemLabels({
        id,
        groupPath: this.fullPath,
        labelIds: labels.map((label) => getIdFromGraphQLId(label.id)),
        labels,
      });
    },
    handleLabelRemove(removeLabelId) {
      this.setActiveBoardItemLabels({
        iid: this.activeBoardItem.iid,
        groupPath: this.fullPath,
        removeLabelIds: [removeLabelId],
      });
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
      variant="sidebar"
      @close="handleClose"
    >
      <template #title>
        <h2 class="gl-my-0 gl-font-size-h2 gl-line-height-24">{{ __('Epic details') }}</h2>
      </template>
      <template #header>
        <sidebar-todo-widget
          class="gl-mt-3"
          :issuable-id="activeBoardItem.id"
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
        <sidebar-labels-widget
          v-if="glFeatures.labelsWidget"
          class="block labels"
          data-testid="sidebar-labels"
          :iid="activeBoardItem.iid"
          :full-path="fullPath"
          :allow-label-remove="canUpdate"
          :allow-multiselect="true"
          :labels-filter-base-path="labelsFilterBasePath"
          :attr-workspace-path="fullPath"
          workspace-type="group"
          :issuable-type="issuableType"
          label-create-type="group"
          @onLabelRemove="handleLabelRemove"
          @updateSelectedLabels="handleUpdateSelectedLabels"
        >
          {{ __('None') }}
        </sidebar-labels-widget>
        <board-sidebar-labels-select v-else class="labels" />
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
