<script>
import { GlAlert, GlButton, GlLoadingIcon, GlTableLite, GlLabel } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';

import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { s__ } from '~/locale';

import { DANGER, INFO, EDIT_BUTTON_LABEL } from '../constants';
import getComplianceFrameworkQuery from '../graphql/queries/get_compliance_framework.query.graphql';
import { injectIdIntoEditPath } from '../utils';
import DeleteModal from './delete_modal.vue';
import EmptyState from './table_empty_state.vue';
import TableActions from './table_actions.vue';

export default {
  components: {
    DeleteModal,
    EmptyState,
    GlAlert,
    GlButton,
    GlLoadingIcon,
    GlTableLite,
    GlLabel,
    TableActions,
  },
  props: {
    addFrameworkPath: {
      type: String,
      required: false,
      default: null,
    },
    editFrameworkPath: {
      type: String,
      required: false,
      default: null,
    },
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
    groupPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      markedForDeletion: {},
      deletingFrameworksIds: [],
      complianceFrameworks: [],
      error: '',
      message: '',
      tableFields: [
        {
          key: 'name',
          label: this.$options.i18n.name,
          thClass: 'w-30p',
          tdClass: 'gl-vertical-align-middle!',
        },
        {
          key: 'description',
          label: this.$options.i18n.description,
          thClass: 'w-60p',
          tdClass: 'gl-vertical-align-middle!',
        },
        {
          key: 'actions',
          label: '',
          thClass: 'w-10p',
          tdClass: 'gl-vertical-align-middle!',
        },
      ],
    };
  },
  apollo: {
    complianceFrameworks: {
      query: getComplianceFrameworkQuery,
      variables() {
        return {
          fullPath: this.groupPath,
        };
      },
      update(data) {
        const nodes = data.namespace?.complianceFrameworks?.nodes;
        return (
          nodes?.map((framework) => {
            const parsedId = getIdFromGraphQLId(framework.id);

            return {
              ...framework,
              parsedId,
              editPath: injectIdIntoEditPath(this.editFrameworkPath, parsedId),
            };
          }) || []
        );
      },
      error(error) {
        this.error = this.$options.i18n.fetchError;
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.loading && this.deletingFrameworksIds.length === 0;
    },
    hasLoaded() {
      return !this.isLoading && !this.error;
    },
    frameworksCount() {
      return this.complianceFrameworks.length;
    },
    isEmpty() {
      return this.hasLoaded && this.frameworksCount === 0;
    },
    hasFrameworks() {
      return this.hasLoaded && this.frameworksCount > 0;
    },
    alertDismissible() {
      return !this.error;
    },
    alertVariant() {
      return this.error ? DANGER : INFO;
    },
    alertMessage() {
      return this.error || this.message;
    },
    showAddButton() {
      return this.hasLoaded && this.addFrameworkPath && !this.isEmpty;
    },
  },
  methods: {
    dismissAlertMessage() {
      this.message = null;
    },
    markForDeletion(framework) {
      this.markedForDeletion = framework;
      this.$refs.modal.show();
    },
    onError() {
      this.error = this.$options.i18n.deleteError;
    },
    onDelete(id) {
      this.message = this.$options.i18n.deleteMessage;
      const idx = this.deletingFrameworksIds.indexOf(id);
      if (idx > -1) {
        this.deletingFrameworksIds.splice(idx, 1);
      }
    },
    onDeleting() {
      this.deletingFrameworksIds.push(this.markedForDeletion.id);
    },
    isDeleting(id) {
      return this.deletingFrameworksIds.includes(id);
    },
  },
  i18n: {
    deleteMessage: s__('ComplianceFrameworks|Compliance framework deleted successfully'),
    deleteError: s__(
      'ComplianceFrameworks|Error deleting the compliance framework. Please try again',
    ),
    fetchError: s__(
      'ComplianceFrameworks|Error fetching compliance frameworks data. Please refresh the page',
    ),
    addBtn: s__('ComplianceFrameworks|Add framework'),
    name: s__('ComplianceFrameworks|Name'),
    description: s__('ComplianceFrameworks|Description'),
    editFramework: EDIT_BUTTON_LABEL,
  },
};
</script>
<template>
  <div>
    <gl-alert
      v-if="alertMessage"
      class="gl-mt-5"
      :variant="alertVariant"
      :dismissible="alertDismissible"
      @dismiss="dismissAlertMessage"
    >
      {{ alertMessage }}
    </gl-alert>
    <gl-loading-icon v-if="isLoading" size="lg" class="gl-mt-5" />
    <empty-state
      v-if="isEmpty"
      :image-path="emptyStateSvgPath"
      :add-framework-path="addFrameworkPath"
    />

    <gl-table-lite v-if="hasFrameworks" :items="complianceFrameworks" :fields="tableFields">
      <template #cell(name)="{ item: framework }">
        <gl-label
          :background-color="framework.color"
          :description="$options.i18n.editFramework"
          :title="framework.name"
          :target="framework.editPath"
        />
      </template>
      <template #cell(description)="{ item: framework }">
        <p data-testid="compliance-framework-description" class="gl-mb-0">
          {{ framework.description }}
        </p>
      </template>
      <template #cell(actions)="{ item: framework }">
        <table-actions
          :key="framework.parsedId"
          :framework="framework"
          :loading="isDeleting(framework.id)"
          @delete="markForDeletion"
        />
      </template>
    </gl-table-lite>

    <gl-button
      v-if="showAddButton"
      class="gl-mt-3"
      category="secondary"
      variant="confirm"
      size="small"
      :href="addFrameworkPath"
    >
      {{ $options.i18n.addBtn }}
    </gl-button>
    <delete-modal
      v-if="hasFrameworks"
      :id="markedForDeletion.id"
      ref="modal"
      :name="markedForDeletion.name"
      :group-path="groupPath"
      @deleting="onDeleting"
      @delete="onDelete"
      @error="onError"
    />
  </div>
</template>
