<script>
import {
  GlButton,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlDisclosureDropdownGroup,
  GlModalDirective,
  GlTooltipDirective,
} from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import { TYPE_EPIC } from '~/issues/constants';
import DeleteIssueModal from '~/issues/show/components/delete_issue_modal.vue';
import issuesEventHub from '~/issues/show/event_hub';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import SidebarSubscriptionsWidget from '~/sidebar/components/subscriptions/sidebar_subscriptions_widget.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import toast from '~/vue_shared/plugins/global_toast';

export default {
  TYPE_EPIC,
  deleteModalId: 'delete-modal-id',
  i18n: {
    copyReferenceText: __('Copy reference'),
    deleteButtonText: __('Delete epic'),
    dropdownText: __('Epic actions'),
    edit: __('Edit'),
    editTitleAndDescription: __('Edit title and description'),
    newEpicText: __('New epic'),
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  components: {
    DeleteIssueModal,
    GlButton,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlDisclosureDropdownGroup,
    SidebarSubscriptionsWidget,
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['fullPath', 'iid'],
  computed: {
    ...mapState([
      'canCreate',
      'canUpdate',
      'canDestroy',
      'epicStatusChangeInProgress',
      'newEpicWebUrl',
      'reference',
    ]),
    ...mapGetters(['isEpicOpen']),
    actionButtonText() {
      return this.isEpicOpen ? __('Close epic') : __('Reopen epic');
    },
    isMrSidebarMoved() {
      return this.glFeatures.movedMrSidebar;
    },
    showDesktopDropdown() {
      return this.canCreate || this.canDestroy || this.isMrSidebarMoved;
    },
    showMobileDropdown() {
      return this.showDesktopDropdown || this.canUpdate;
    },
    showNotificationToggle() {
      return this.isMrSidebarMoved && isLoggedIn();
    },
    newEpicDropdownItem() {
      return {
        text: this.$options.i18n.newEpicText,
        href: this.newEpicWebUrl,
      };
    },
    copyReferenceDropdownItem() {
      return {
        text: this.$options.i18n.copyReferenceText,
        action: this.closeDropdownAfterAction.bind(this, this.copyReference),
        extraAttrs: {
          'data-clipboard-text': this.reference,
          class: 'js-copy-reference',
        },
      };
    },
    toggleEpicStatusDropdownItem() {
      return {
        text: this.actionButtonText,
        action: this.closeDropdownAfterAction.bind(
          this,
          this.toggleEpicStatus.bind(this, this.isEpicOpen),
        ),
        extraAttrs: {
          'data-testid': 'toggle-status-button',
        },
      };
    },
    actionsDropdownGroupMobile() {
      const items = [];

      if (this.canUpdate) {
        items.push({
          text: this.$options.i18n.edit,
          action: this.closeDropdownAfterAction.bind(this, this.editEpic),
        });
      }

      if (this.canCreate) {
        items.push(this.newEpicDropdownItem);
      }

      if (this.canUpdate) {
        items.push(this.toggleEpicStatusDropdownItem);
      }

      if (this.isMrSidebarMoved) {
        items.push(this.copyReferenceDropdownItem);
      }

      return { items };
    },
    actionsDropdownGroupDesktop() {
      const items = [];

      if (this.canUpdate && this.glFeatures.moveCloseIntoDropdown) {
        items.push(this.toggleEpicStatusDropdownItem);
      }

      if (this.canCreate) {
        items.push(this.newEpicDropdownItem);
      }

      if (this.isMrSidebarMoved) {
        items.push(this.copyReferenceDropdownItem);
      }

      return { items };
    },
  },
  methods: {
    ...mapActions(['toggleEpicStatus']),
    closeDropdownAfterAction(action) {
      action();
      this.closeActionsDropdown();
    },
    copyReference() {
      toast(__('Reference copied'));
    },
    editEpic() {
      issuesEventHub.$emit('open.form');
    },
    closeActionsDropdown() {
      this.$refs.epicActionsDropdownMobile?.close();
      this.$refs.epicActionsDropdownDesktop?.close();
    },
  },
};
</script>

<template>
  <div class="gl-display-contents">
    <gl-disclosure-dropdown
      v-if="showMobileDropdown"
      ref="epicActionsDropdownMobile"
      class="gl-display-block gl-sm-display-none! gl-w-full gl-mt-3"
      category="secondary"
      :auto-close="false"
      toggle-class="gl-w-full"
      :toggle-text="$options.i18n.dropdownText"
    >
      <gl-disclosure-dropdown-group v-if="showNotificationToggle">
        <sidebar-subscriptions-widget
          :iid="String(iid)"
          :full-path="fullPath"
          :issuable-type="$options.TYPE_EPIC"
        />
      </gl-disclosure-dropdown-group>

      <gl-disclosure-dropdown-group :group="actionsDropdownGroupMobile" bordered />
      <gl-disclosure-dropdown-group v-if="canDestroy" bordered>
        <gl-disclosure-dropdown-item v-gl-modal="$options.deleteModalId">
          <template #list-item>
            <span class="gl-text-red-500">
              {{ $options.i18n.deleteButtonText }}
            </span>
          </template>
        </gl-disclosure-dropdown-item>
      </gl-disclosure-dropdown-group>
    </gl-disclosure-dropdown>

    <gl-button
      v-if="canUpdate"
      :title="$options.i18n.editTitleAndDescription"
      :aria-label="$options.i18n.editTitleAndDescription"
      category="secondary"
      class="js-issuable-edit gl-display-none gl-sm-display-block"
      @click="editEpic"
    >
      {{ $options.i18n.edit }}
    </gl-button>

    <gl-button
      v-if="canUpdate && !glFeatures.moveCloseIntoDropdown"
      :loading="epicStatusChangeInProgress"
      category="secondary"
      class="gl-display-none gl-sm-display-block gl-sm-ml-3"
      data-testid="toggle-status-button"
      @click="toggleEpicStatus(isEpicOpen)"
    >
      {{ actionButtonText }}
    </gl-button>

    <gl-disclosure-dropdown
      v-if="showDesktopDropdown"
      ref="epicActionsDropdownDesktop"
      class="gl-display-none gl-sm-display-block gl-ml-3"
      placement="right"
      :auto-close="false"
      data-testid="desktop-dropdown"
      :toggle-text="$options.i18n.dropdownText"
      text-sr-only
      icon="ellipsis_v"
      category="tertiary"
      no-caret
    >
      <gl-disclosure-dropdown-group v-if="showNotificationToggle">
        <sidebar-subscriptions-widget
          :iid="String(iid)"
          :full-path="fullPath"
          :issuable-type="$options.TYPE_EPIC"
        />
      </gl-disclosure-dropdown-group>

      <gl-disclosure-dropdown-group :group="actionsDropdownGroupDesktop" bordered />

      <gl-disclosure-dropdown-group v-if="canDestroy" bordered>
        <gl-disclosure-dropdown-item v-gl-modal="$options.deleteModalId">
          <template #list-item>
            <span class="gl-text-red-500">
              {{ $options.i18n.deleteButtonText }}
            </span>
          </template>
        </gl-disclosure-dropdown-item>
      </gl-disclosure-dropdown-group>
    </gl-disclosure-dropdown>

    <delete-issue-modal
      :issue-type="$options.TYPE_EPIC"
      :modal-id="$options.deleteModalId"
      :title="$options.i18n.deleteButtonText"
    />
  </div>
</template>
