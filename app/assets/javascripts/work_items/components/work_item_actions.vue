<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlDropdownDivider,
  GlModal,
  GlModalDirective,
  GlToggle,
} from '@gitlab/ui';
import { produce } from 'immer';

import * as Sentry from '@sentry/browser';

import { __, s__ } from '~/locale';
import Tracking from '~/tracking';
import toast from '~/vue_shared/plugins/global_toast';
import { isLoggedIn } from '~/lib/utils/common_utils';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';

import {
  sprintfWorkItem,
  I18N_WORK_ITEM_DELETE,
  I18N_WORK_ITEM_ARE_YOU_SURE_DELETE,
  TEST_ID_CONFIDENTIALITY_TOGGLE_ACTION,
  TEST_ID_NOTIFICATIONS_TOGGLE_ACTION,
  TEST_ID_NOTIFICATIONS_TOGGLE_FORM,
  TEST_ID_DELETE_ACTION,
  TEST_ID_PROMOTE_ACTION,
  TEST_ID_COPY_CREATE_NOTE_EMAIL_ACTION,
  TEST_ID_COPY_REFERENCE_ACTION,
  WIDGET_TYPE_NOTIFICATIONS,
  I18N_WORK_ITEM_ERROR_CONVERTING,
  WORK_ITEM_TYPE_VALUE_KEY_RESULT,
  WORK_ITEM_TYPE_VALUE_OBJECTIVE,
  I18N_WORK_ITEM_COPY_CREATE_NOTE_EMAIL,
  I18N_WORK_ITEM_ERROR_COPY_REFERENCE,
  I18N_WORK_ITEM_ERROR_COPY_EMAIL,
} from '../constants';
import updateWorkItemNotificationsMutation from '../graphql/update_work_item_notifications.mutation.graphql';
import convertWorkItemMutation from '../graphql/work_item_convert.mutation.graphql';
import projectWorkItemTypesQuery from '../graphql/project_work_item_types.query.graphql';

export default {
  i18n: {
    enableTaskConfidentiality: s__('WorkItem|Turn on confidentiality'),
    disableTaskConfidentiality: s__('WorkItem|Turn off confidentiality'),
    notifications: s__('WorkItem|Notifications'),
    notificationOn: s__('WorkItem|Notifications turned on.'),
    notificationOff: s__('WorkItem|Notifications turned off.'),
    copyReference: __('Copy reference'),
    referenceCopied: __('Reference copied'),
    emailAddressCopied: __('Email address copied'),
  },
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlDropdownDivider,
    GlModal,
    GlToggle,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  mixins: [Tracking.mixin({ label: 'actions_menu' })],
  isLoggedIn: isLoggedIn(),
  notificationsToggleTestId: TEST_ID_NOTIFICATIONS_TOGGLE_ACTION,
  notificationsToggleFormTestId: TEST_ID_NOTIFICATIONS_TOGGLE_FORM,
  confidentialityTestId: TEST_ID_CONFIDENTIALITY_TOGGLE_ACTION,
  copyReferenceTestId: TEST_ID_COPY_REFERENCE_ACTION,
  copyCreateNoteEmailTestId: TEST_ID_COPY_CREATE_NOTE_EMAIL_ACTION,
  deleteActionTestId: TEST_ID_DELETE_ACTION,
  promoteActionTestId: TEST_ID_PROMOTE_ACTION,
  inject: ['fullPath'],
  props: {
    workItemId: {
      type: String,
      required: false,
      default: null,
    },
    workItemType: {
      type: String,
      required: false,
      default: null,
    },
    workItemTypeId: {
      type: String,
      required: false,
      default: null,
    },
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    canDelete: {
      type: Boolean,
      required: false,
      default: false,
    },
    isConfidential: {
      type: Boolean,
      required: false,
      default: false,
    },
    isParentConfidential: {
      type: Boolean,
      required: false,
      default: false,
    },
    subscribedToNotifications: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemReference: {
      type: String,
      required: false,
      default: null,
    },
    workItemCreateNoteEmail: {
      type: String,
      required: false,
      default: null,
    },
    isModal: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemIid: {
      type: String,
      required: true,
    },
  },
  apollo: {
    workItemTypes: {
      query: projectWorkItemTypesQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update(data) {
        return data.workspace?.workItemTypes?.nodes;
      },
      skip() {
        return !this.canUpdate;
      },
    },
  },
  computed: {
    i18n() {
      return {
        deleteWorkItem: sprintfWorkItem(I18N_WORK_ITEM_DELETE, this.workItemType),
        areYouSureDelete: sprintfWorkItem(I18N_WORK_ITEM_ARE_YOU_SURE_DELETE, this.workItemType),
        convertError: sprintfWorkItem(I18N_WORK_ITEM_ERROR_CONVERTING, this.workItemType),
        copyCreateNoteEmail: sprintfWorkItem(
          I18N_WORK_ITEM_COPY_CREATE_NOTE_EMAIL,
          this.workItemType,
        ),
        copyReferenceError: sprintfWorkItem(I18N_WORK_ITEM_ERROR_COPY_REFERENCE, this.workItemType),
        copyCreateNoteEmailError: sprintfWorkItem(
          I18N_WORK_ITEM_ERROR_COPY_EMAIL,
          this.workItemType,
        ),
      };
    },
    canPromoteToObjective() {
      return this.canUpdate && this.workItemType === WORK_ITEM_TYPE_VALUE_KEY_RESULT;
    },
    objectiveWorkItemTypeId() {
      return this.workItemTypes.find((type) => type.name === WORK_ITEM_TYPE_VALUE_OBJECTIVE).id;
    },
  },
  methods: {
    copyToClipboard(text, message) {
      if (this.isModal) {
        navigator.clipboard.writeText(text);
      }
      toast(message);
      this.closeDropdown();
    },
    handleToggleWorkItemConfidentiality() {
      this.track('click_toggle_work_item_confidentiality');
      this.$emit('toggleWorkItemConfidentiality', !this.isConfidential);
      this.closeDropdown();
    },
    handleDelete() {
      this.$refs.modal.show();
      this.closeDropdown();
    },
    handleDeleteWorkItem() {
      this.track('click_delete_work_item');
      this.$emit('deleteWorkItem');
    },
    handleCancelDeleteWorkItem({ trigger }) {
      if (trigger !== 'ok') {
        this.track('cancel_delete_work_item');
      }
    },
    toggleNotifications(subscribed) {
      const inputVariables = {
        projectPath: this.fullPath,
        iid: this.workItemIid,
        subscribedState: subscribed,
      };
      this.$apollo
        .mutate({
          mutation: updateWorkItemNotificationsMutation,
          variables: {
            input: inputVariables,
          },
          optimisticResponse: {
            updateWorkItemNotificationsSubscription: {
              issue: {
                id: this.workItemId,
                subscribed,
              },
              errors: [],
            },
          },
          update: (
            cache,
            {
              data: {
                updateWorkItemNotificationsSubscription: { issue = {} },
              },
            },
          ) => {
            // As the mutation and the query both are different,
            // overwrite the subscribed value in the cache
            this.updateWorkItemNotificationsWidgetCache({
              cache,
              issue,
            });
          },
        })
        .then(
          ({
            data: {
              updateWorkItemNotificationsSubscription: { errors },
            },
          }) => {
            if (errors?.length) {
              throw new Error(errors[0]);
            }
            toast(
              subscribed ? this.$options.i18n.notificationOn : this.$options.i18n.notificationOff,
            );
          },
        )
        .catch((error) => {
          this.$emit('error', error.message);
          Sentry.captureException(error);
        });
    },
    updateWorkItemNotificationsWidgetCache({ cache, issue }) {
      const query = {
        query: workItemByIidQuery,
        variables: { fullPath: this.fullPath, iid: this.workItemIid },
      };
      // Read the work item object
      const sourceData = cache.readQuery(query);

      const newData = produce(sourceData, (draftState) => {
        const { widgets } = draftState.workspace.workItems.nodes[0];

        const widgetNotifications = widgets.find(({ type }) => type === WIDGET_TYPE_NOTIFICATIONS);
        // overwrite the subscribed value
        widgetNotifications.subscribed = issue.subscribed;
      });

      // write to the cache
      cache.writeQuery({ ...query, data: newData });
    },
    throwConvertError() {
      this.$emit('error', this.i18n.convertError);
    },
    closeDropdown() {
      this.$refs.workItemsMoreActions.close();
    },
    async promoteToObjective() {
      try {
        const {
          data: {
            workItemConvert: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: convertWorkItemMutation,
          variables: {
            input: {
              id: this.workItemId,
              workItemTypeId: this.objectiveWorkItemTypeId,
            },
          },
        });
        if (errors.length > 0) {
          this.throwConvertError();
          return;
        }
        this.$toast.show(s__('WorkItem|Promoted to objective.'));
        this.track('promote_kr_to_objective');
        this.$emit('promotedToObjective');
      } catch (error) {
        this.throwConvertError();
        Sentry.captureException(error);
      } finally {
        this.closeDropdown();
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-disclosure-dropdown
      ref="workItemsMoreActions"
      icon="ellipsis_v"
      data-testid="work-item-actions-dropdown"
      text-sr-only
      :text="__('More actions')"
      category="tertiary"
      :auto-close="false"
      no-caret
      right
    >
      <template v-if="$options.isLoggedIn">
        <gl-disclosure-dropdown-item
          class="gl-display-flex gl-justify-content-end gl-w-full"
          :data-testid="$options.notificationsToggleFormTestId"
        >
          <template #list-item>
            <gl-toggle
              :value="subscribedToNotifications"
              :label="$options.i18n.notifications"
              :data-testid="$options.notificationsToggleTestId"
              class="work-item-notification-toggle"
              label-position="left"
              label-id="notifications-toggle"
              @change="toggleNotifications($event)"
            />
          </template>
        </gl-disclosure-dropdown-item>
        <gl-dropdown-divider />
      </template>

      <gl-disclosure-dropdown-item
        v-if="canPromoteToObjective"
        :data-testid="$options.promoteActionTestId"
        @action="promoteToObjective"
      >
        <template #list-item>{{ __('Promote to objective') }}</template>
      </gl-disclosure-dropdown-item>
      <template v-if="canUpdate && !isParentConfidential">
        <gl-disclosure-dropdown-item
          :data-testid="$options.confidentialityTestId"
          @action="handleToggleWorkItemConfidentiality"
          ><template #list-item>{{
            isConfidential
              ? $options.i18n.disableTaskConfidentiality
              : $options.i18n.enableTaskConfidentiality
          }}</template></gl-disclosure-dropdown-item
        >
      </template>
      <gl-disclosure-dropdown-item
        ref="workItemReference"
        :data-testid="$options.copyReferenceTestId"
        :data-clipboard-text="workItemReference"
        @action="copyToClipboard(workItemReference, $options.i18n.referenceCopied)"
        ><template #list-item>{{
          $options.i18n.copyReference
        }}</template></gl-disclosure-dropdown-item
      >
      <template v-if="$options.isLoggedIn && workItemCreateNoteEmail">
        <gl-disclosure-dropdown-item
          ref="workItemCreateNoteEmail"
          :data-testid="$options.copyCreateNoteEmailTestId"
          :data-clipboard-text="workItemCreateNoteEmail"
          @action="copyToClipboard(workItemCreateNoteEmail, $options.i18n.emailAddressCopied)"
          ><template #list-item>{{
            i18n.copyCreateNoteEmail
          }}</template></gl-disclosure-dropdown-item
        >
      </template>
      <gl-dropdown-divider v-if="canDelete" />
      <gl-disclosure-dropdown-item
        v-if="canDelete"
        :data-testid="$options.deleteActionTestId"
        variant="danger"
        @action="handleDelete"
      >
        <template #list-item
          ><span class="text-danger">{{ i18n.deleteWorkItem }}</span></template
        >
      </gl-disclosure-dropdown-item>
    </gl-disclosure-dropdown>
    <gl-modal
      ref="modal"
      modal-id="work-item-confirm-delete"
      :title="i18n.deleteWorkItem"
      :ok-title="i18n.deleteWorkItem"
      ok-variant="danger"
      @ok="handleDeleteWorkItem"
      @hide="handleCancelDeleteWorkItem"
    >
      {{ i18n.areYouSureDelete }}
    </gl-modal>
  </div>
</template>
