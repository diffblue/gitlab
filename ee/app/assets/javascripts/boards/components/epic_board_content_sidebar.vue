<script>
import { GlDrawer } from '@gitlab/ui';
import { MountingPortal } from 'portal-vue';
import { mapState, mapActions, mapGetters } from 'vuex';
import activeBoardItemQuery from 'ee_else_ce/boards/graphql/client/active_board_item.query.graphql';
import setActiveBoardItemMutation from 'ee_else_ce/boards/graphql/client/set_active_board_item.mutation.graphql';
import SidebarAncestorsWidget from 'ee_component/sidebar/components/ancestors_tree/sidebar_ancestors_widget.vue';
import BoardSidebarTitle from '~/boards/components/sidebar/board_sidebar_title.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import SidebarConfidentialityWidget from '~/sidebar/components/confidential/sidebar_confidentiality_widget.vue';
import SidebarDateWidget from '~/sidebar/components/date/sidebar_date_widget.vue';
import SidebarParticipantsWidget from '~/sidebar/components/participants/sidebar_participants_widget.vue';
import SidebarSubscriptionsWidget from '~/sidebar/components/subscriptions/sidebar_subscriptions_widget.vue';
import SidebarTodoWidget from '~/sidebar/components/todo_toggle/sidebar_todo_widget.vue';
import SidebarLabelsWidget from '~/sidebar/components/labels/labels_select_widget/labels_select_root.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import ColorSelectDropdown from '~/vue_shared/components/color_select_dropdown/color_select_root.vue';

export default {
  components: {
    BoardSidebarTitle,
    ColorSelectDropdown,
    GlDrawer,
    MountingPortal,
    SidebarAncestorsWidget,
    SidebarConfidentialityWidget,
    SidebarDateWidget,
    SidebarLabelsWidget,
    SidebarParticipantsWidget,
    SidebarSubscriptionsWidget,
    SidebarTodoWidget,
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['canUpdate', 'labelsFilterBasePath', 'issuableType', 'isApolloBoard'],
  inheritAttrs: false,
  apollo: {
    activeBoardCard: {
      query: activeBoardItemQuery,
      variables: {
        isIssue: false,
      },
      update(data) {
        if (!data.activeBoardItem?.id) {
          return { id: '', iid: '' };
        }
        return data.activeBoardItem;
      },
      skip() {
        return !this.isApolloBoard;
      },
    },
  },
  computed: {
    ...mapGetters(['activeBoardItem']),
    ...mapState(['sidebarType']),
    activeBoardIssuable() {
      return this.isApolloBoard ? this.activeBoardCard : this.activeBoardItem;
    },
    isSidebarOpen() {
      return Boolean(this.activeBoardIssuable?.id);
    },
    fullPath() {
      return this.activeBoardIssuable?.referencePath?.split('&')[0] || '';
    },
    isEpicColorEnabled() {
      return this.glFeatures.epicColorHighlight;
    },
  },
  methods: {
    ...mapActions([
      'toggleBoardItem',
      'setActiveItemConfidential',
      'setActiveItemSubscribed',
      'setActiveBoardItemLabels',
      'setActiveBoardItemColor',
    ]),
    handleClose() {
      if (this.isApolloBoard) {
        this.$apollo.mutate({
          mutation: setActiveBoardItemMutation,
          variables: {
            boardItem: null,
          },
        });
      } else {
        this.toggleBoardItem({
          boardItem: this.activeBoardIssuable,
          sidebarType: this.sidebarType,
        });
      }
    },
    handleUpdateSelectedLabels({ labels, id }) {
      this.setActiveBoardItemLabels({
        id,
        groupPath: this.fullPath,
        labelIds: labels.map((label) => getIdFromGraphQLId(label.id)),
        labels,
      });
    },
    handleUpdateSelectedColor({ id, color }) {
      this.setActiveBoardItemColor({
        id,
        groupPath: this.fullPath,
        color,
      });
    },
    handleLabelRemove(removeLabelId) {
      this.setActiveBoardItemLabels({
        iid: this.activeBoardIssuable.iid,
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
      v-bind="$attrs"
      class="boards-sidebar"
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
          :issuable-id="activeBoardIssuable.id"
          :issuable-iid="activeBoardIssuable.iid"
          :full-path="fullPath"
          :issuable-type="issuableType"
        />
      </template>
      <template #default>
        <board-sidebar-title :active-item="activeBoardIssuable" data-testid="sidebar-title" />
        <sidebar-date-widget
          :iid="activeBoardIssuable.iid"
          :full-path="fullPath"
          date-type="startDate"
          :issuable-type="issuableType"
          :can-inherit="true"
        />
        <sidebar-date-widget
          :iid="activeBoardIssuable.iid"
          :full-path="fullPath"
          date-type="dueDate"
          :issuable-type="issuableType"
          :can-inherit="true"
        />
        <sidebar-labels-widget
          class="block labels"
          data-testid="sidebar-labels"
          :iid="activeBoardIssuable.iid"
          :full-path="fullPath"
          :allow-label-remove="canUpdate"
          :allow-multiselect="true"
          :labels-filter-base-path="labelsFilterBasePath"
          :attr-workspace-path="fullPath"
          workspace-type="group"
          :issuable-type="issuableType"
          label-create-type="group"
          @onLabelRemove="!isApolloBoard && handleLabelRemove($event)"
          @updateSelectedLabels="!isApolloBoard && handleUpdateSelectedLabels($event)"
        >
          {{ __('None') }}
        </sidebar-labels-widget>

        <color-select-dropdown
          v-if="isEpicColorEnabled"
          class="block colors js-colors-block"
          :allow-edit="canUpdate"
          :iid="activeBoardIssuable.iid"
          :full-path="fullPath"
          workspace-type="group"
          issuable-type="epic"
          variant="sidebar"
          data-testid="colors-select"
          @updateSelectedColor="!isApolloBoard && handleUpdateSelectedColor($event)"
        >
          {{ __('None') }}
        </color-select-dropdown>

        <sidebar-confidentiality-widget
          :iid="activeBoardIssuable.iid"
          :full-path="fullPath"
          :issuable-type="issuableType"
          @confidentialityUpdated="!isApolloBoard && setActiveItemConfidential($event)"
        />
        <sidebar-ancestors-widget
          :iid="activeBoardIssuable.iid"
          :full-path="fullPath"
          issuable-type="epic"
        />
        <sidebar-participants-widget
          :iid="activeBoardIssuable.iid"
          :full-path="fullPath"
          issuable-type="epic"
        />
        <sidebar-subscriptions-widget
          :iid="activeBoardIssuable.iid"
          :full-path="fullPath"
          :issuable-type="issuableType"
        />
      </template>
    </gl-drawer>
  </mounting-portal>
</template>
