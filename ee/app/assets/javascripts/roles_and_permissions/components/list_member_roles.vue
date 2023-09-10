<script>
import { GlBadge, GlButton, GlCard, GlEmptyState, GlModal, GlTable } from '@gitlab/ui';
import { deleteMemberRole, getMemberRoles } from 'ee/rest_api';
import { ACCESS_LEVEL_LABELS } from '~/access_level/constants';
import { createAlert, VARIANT_DANGER } from '~/alert';
import { HTTP_STATUS_NOT_FOUND } from '~/lib/utils/http_status';
import {
  FIELDS,
  I18N_ADD_NEW_ROLE,
  I18N_CANCEL,
  I18N_CARD_TITLE,
  I18N_CREATION_SUCCESS,
  I18N_DELETE_ROLE,
  I18N_DELETION_ERROR,
  I18N_DELETION_SUCCESS,
  I18N_EMPTY_TITLE,
  I18N_FETCH_ERROR,
  I18N_LICENSE_ERROR,
  I18N_MODAL_TITLE,
  I18N_MODAL_WARNING,
  PERMISSIONS,
} from '../constants';
import CreateMemberRole from './create_member_role.vue';

export default {
  name: 'ListMemberRoles',
  components: {
    CreateMemberRole,
    GlBadge,
    GlButton,
    GlCard,
    GlEmptyState,
    GlModal,
    GlTable,
  },
  props: {
    emptyText: {
      type: String,
      required: false,
      default: null,
    },
    groupId: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      alert: null,
      loading: false,
      memberRoles: [],
      memberRoleToDelete: null,
      showCreateMemberForm: false,
    };
  },
  computed: {
    isModalVisible() {
      return this.memberRoleToDelete !== null;
    },
  },
  watch: {
    groupId: function newFetch(newGroupId) {
      this.fetchMemberRoles(newGroupId);
    },
  },
  created() {
    this.fetchMemberRoles(this.groupId);
  },
  methods: {
    async deleteMemberRole() {
      this.alert?.dismiss();

      try {
        await deleteMemberRole(this.groupId, this.memberRoleToDelete);
        this.$toast.show(I18N_DELETION_SUCCESS);
        this.fetchMemberRoles(this.groupId);
      } catch (error) {
        this.alert = createAlert({
          message: error.response?.data?.message || I18N_DELETION_ERROR,
          variant: VARIANT_DANGER,
        });
      } finally {
        this.memberRoleToDelete = null;
      }
    },
    async fetchMemberRoles(groupId) {
      this.alert?.dismiss();

      if (!groupId) {
        this.memberRoles = [];
        return;
      }
      this.loading = true;

      try {
        const { data } = await getMemberRoles(groupId);
        this.memberRoles = data;
      } catch (error) {
        this.memberRoles = [];
        if (error?.response?.status === HTTP_STATUS_NOT_FOUND) {
          this.alert = createAlert({
            message: I18N_LICENSE_ERROR,
            variant: VARIANT_DANGER,
          });
        } else {
          this.alert = createAlert({
            message: error?.response?.data?.message || I18N_FETCH_ERROR,
            variant: VARIANT_DANGER,
          });
        }
      } finally {
        this.loading = false;
      }
    },
    listPermissions(item) {
      return Object.entries(item).flatMap(([key, value]) => {
        if (value !== true) {
          return [];
        }
        return [PERMISSIONS[item.base_access_level]?.[key]?.text || key];
      });
    },
    nameAccessLevel(value) {
      return ACCESS_LEVEL_LABELS[value];
    },
    onCreatedMemberRole() {
      this.$toast.show(I18N_CREATION_SUCCESS);
      this.showCreateMemberForm = false;
      this.fetchMemberRoles(this.groupId);
    },
    onModalHide() {
      this.memberRoleToDelete = null;
    },
    showConfirm(memberRoleId) {
      this.memberRoleToDelete = `${memberRoleId}`;
    },
  },
  FIELDS,
  i18n: {
    addNewRole: I18N_ADD_NEW_ROLE,
    cardTitle: I18N_CARD_TITLE,
    deleteRole: I18N_DELETE_ROLE,
    emptyTitle: I18N_EMPTY_TITLE,
  },
  modal: {
    actionPrimary: {
      text: I18N_DELETE_ROLE,
      attributes: {
        variant: 'danger',
      },
    },
    actionSecondary: {
      text: I18N_CANCEL,
      attributes: {
        variant: 'default',
      },
    },
    id: 'confirm-delete-role',
    title: I18N_MODAL_TITLE,
    warning: I18N_MODAL_WARNING,
  },
};
</script>

<template>
  <gl-card header-class="gl-new-card-header" body-class="gl-new-card-body gl-px-0 gl-bg-gray-10">
    <template #header>
      <div class="gl-new-card-title-wrapper">
        <h3 class="gl-new-card-title" data-testid="card-title">
          {{ $options.i18n.cardTitle }}
          <span class="gl-new-card-count" data-testid="counter">{{ memberRoles.length }}</span>
        </h3>
      </div>
      <div class="gl-new-card-actions">
        <gl-button
          :disabled="!groupId"
          size="small"
          data-testid="add-role"
          @click="showCreateMemberForm = true"
          >{{ $options.i18n.addNewRole }}</gl-button
        >
      </div>
    </template>

    <div v-if="showCreateMemberForm" class="gl-new-card-add-form gl-m-3">
      <create-member-role
        :group-id="groupId"
        @cancel="showCreateMemberForm = false"
        @success="onCreatedMemberRole"
      />
    </div>

    <gl-empty-state
      v-if="memberRoles.length === 0"
      :title="$options.i18n.emptyTitle"
      :description="emptyText"
    />

    <gl-table v-else :fields="$options.FIELDS" :items="memberRoles" :busy="loading" stacked="sm">
      <template #cell(base_access_level)="{ item: { base_access_level } }">
        <gl-badge class="gl-my-n4">{{ nameAccessLevel(base_access_level) }}</gl-badge>
      </template>

      <template #cell(permissions)="{ item }">
        <div
          class="gl-display-flex gl-flex-wrap gl-gap-3 gl-justify-content-end gl-sm-justify-content-start"
        >
          <gl-badge
            v-for="(permission, index) in listPermissions(item)"
            :key="index"
            variant="success"
            size="sm"
            >{{ permission }}</gl-badge
          >
        </div>
      </template>

      <template #cell(actions)="{ item: { id } }">
        <gl-button
          class="gl-my-n4"
          category="tertiary"
          :aria-label="$options.i18n.deleteRole"
          icon="remove"
          @click="showConfirm(id)"
        />
      </template>
    </gl-table>

    <gl-modal
      :visible="isModalVisible"
      :modal-id="$options.modal.id"
      size="sm"
      :title="$options.modal.title"
      :action-primary="$options.modal.actionPrimary"
      :action-secondary="$options.modal.actionSecondary"
      @primary="deleteMemberRole"
      @hide="onModalHide"
    >
      <p>{{ $options.modal.warning }}</p>
    </gl-modal>
  </gl-card>
</template>
