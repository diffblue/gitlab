<script>
import {
  GlButton,
  GlDropdown,
  GlDropdownDivider,
  GlDropdownItem,
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
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
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
    actionButtonClass() {
      return this.isEpicOpen ? 'btn-close' : 'btn-open';
    },
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
  },
  methods: {
    ...mapActions(['toggleEpicStatus']),
    copyReference() {
      toast(__('Reference copied'));
    },
    editEpic() {
      issuesEventHub.$emit('open.form');
    },
  },
};
</script>

<template>
  <div class="gl-display-contents">
    <gl-dropdown
      v-if="showMobileDropdown"
      class="gl-sm-display-none gl-w-full gl-mt-3"
      block
      :text="$options.i18n.dropdownText"
    >
      <template v-if="showNotificationToggle">
        <sidebar-subscriptions-widget
          :iid="String(iid)"
          :full-path="fullPath"
          :issuable-type="$options.TYPE_EPIC"
        />
        <gl-dropdown-divider />
      </template>
      <gl-dropdown-item v-if="canUpdate" @click="editEpic">
        {{ $options.i18n.edit }}
      </gl-dropdown-item>
      <gl-dropdown-item v-if="canCreate" :href="newEpicWebUrl">
        {{ $options.i18n.newEpicText }}
      </gl-dropdown-item>
      <gl-dropdown-item v-if="canUpdate" @click="toggleEpicStatus(isEpicOpen)">
        {{ actionButtonText }}
      </gl-dropdown-item>
      <gl-dropdown-item
        v-if="isMrSidebarMoved"
        :data-clipboard-text="reference"
        @click="copyReference"
        >{{ $options.i18n.copyReferenceText }}
      </gl-dropdown-item>
      <template v-if="canDestroy">
        <gl-dropdown-divider />
        <gl-dropdown-item v-gl-modal="$options.deleteModalId" variant="danger">
          {{ $options.i18n.deleteButtonText }}
        </gl-dropdown-item>
      </template>
    </gl-dropdown>

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
      :class="actionButtonClass"
      category="secondary"
      class="gl-display-none gl-sm-display-block gl-sm-ml-3"
      data-testid="toggle-status-button"
      @click="toggleEpicStatus(isEpicOpen)"
    >
      {{ actionButtonText }}
    </gl-button>

    <gl-dropdown
      v-if="showDesktopDropdown"
      v-gl-tooltip.hover
      class="gl-display-none gl-sm-display-inline-flex gl-sm-ml-3"
      icon="ellipsis_v"
      category="tertiary"
      :text="$options.i18n.dropdownText"
      text-sr-only
      :title="$options.i18n.dropdownText"
      :aria-label="$options.i18n.dropdownText"
      data-testid="desktop-dropdown"
      no-caret
      right
    >
      <template v-if="showNotificationToggle">
        <sidebar-subscriptions-widget
          :iid="String(iid)"
          :full-path="fullPath"
          :issuable-type="$options.TYPE_EPIC"
        />
        <gl-dropdown-divider />
      </template>
      <gl-dropdown-item
        v-if="canUpdate && glFeatures.moveCloseIntoDropdown"
        data-testid="toggle-status-button"
        @click="toggleEpicStatus(isEpicOpen)"
      >
        {{ actionButtonText }}
      </gl-dropdown-item>
      <gl-dropdown-item v-if="canCreate" :href="newEpicWebUrl">
        {{ $options.i18n.newEpicText }}
      </gl-dropdown-item>

      <template v-if="isMrSidebarMoved">
        <gl-dropdown-item :data-clipboard-text="reference" @click="copyReference"
          >{{ $options.i18n.copyReferenceText }}
        </gl-dropdown-item>
      </template>

      <template v-if="canDestroy">
        <gl-dropdown-divider />
        <gl-dropdown-item v-gl-modal="$options.deleteModalId" variant="danger">
          {{ $options.i18n.deleteButtonText }}
        </gl-dropdown-item>
      </template>
    </gl-dropdown>

    <delete-issue-modal
      :issue-type="$options.TYPE_EPIC"
      :modal-id="$options.deleteModalId"
      :title="$options.i18n.deleteButtonText"
    />
  </div>
</template>
