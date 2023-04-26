<script>
import Vue from 'vue';
import {
  GlAlert,
  GlBadge,
  GlButton,
  GlLoadingIcon,
  GlTableLite,
  GlLabel,
  GlToast,
} from '@gitlab/ui';
import * as Sentry from '@sentry/browser';

import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import getComplianceFrameworkQuery from 'ee/graphql_shared/queries/get_compliance_framework.query.graphql';
import { s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import { DANGER, INFO, EDIT_BUTTON_LABEL } from '../constants';
import updateComplianceFrameworkMutation from '../graphql/queries/update_compliance_framework.mutation.graphql';
import { injectIdIntoEditPath } from '../utils';
import DeleteModal from './delete_modal.vue';
import EmptyState from './table_empty_state.vue';
import TableActions from './table_actions.vue';
import FormModal from './form_modal.vue';

Vue.use(GlToast);

export default {
  components: {
    DeleteModal,
    EmptyState,
    FormModal,
    GlAlert,
    GlBadge,
    GlButton,
    GlLoadingIcon,
    GlTableLite,
    GlLabel,
    TableActions,
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['groupPath'],
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
  },
  data() {
    return {
      markedForEdit: {},
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
        this.setError(error, this.$options.i18n.fetchError);
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
    addFrameworkHref() {
      return this.glFeatures.manageComplianceFrameworksModalsRefactor
        ? undefined
        : this.addFrameworkPath;
    },
  },
  methods: {
    onClickAdd(event) {
      if (!this.glFeatures.manageComplianceFrameworksModalsRefactor) {
        return;
      }

      event?.preventDefault();
      this.markForAdd();
    },
    setError(error, userFriendlyText) {
      this.error = userFriendlyText;
      Sentry.captureException(error);
    },
    dismissAlertMessage() {
      this.message = null;
    },
    markForAdd() {
      this.markedForEdit = {};
      this.$refs.formModal.show();
    },
    markForEdit(framework) {
      this.markedForEdit = framework;
      this.$refs.formModal.show();
    },
    markForDeletion(framework) {
      this.markedForDeletion = framework;
      this.$refs.deleteModal.show();
    },
    onError() {
      this.error = this.$options.i18n.deleteError;
    },
    onChange(userFriendlyText) {
      this.$refs.formModal.hide();
      this.$toast.show(userFriendlyText);
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
    async setDefaultFramework({ framework, defaultVal }) {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: updateComplianceFrameworkMutation,
          variables: {
            input: {
              id: framework.id,
              params: { default: defaultVal },
            },
          },
          awaitRefetchQueries: true,
          refetchQueries: [
            {
              query: getComplianceFrameworkQuery,
              variables: {
                fullPath: this.groupPath,
              },
            },
          ],
        });

        const [error] = data?.updateComplianceFramework?.errors || [];

        if (error) {
          throw new Error(error);
        }

        this.message = this.$options.i18n.setDefaultMessage;
      } catch (error) {
        this.setError(error, this.$options.i18n.setDefaultError);
      }
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
    default: s__('ComplianceFrameworks|default'),
    editFramework: EDIT_BUTTON_LABEL,
    setDefaultMessage: s__(
      'ComplianceFrameworks|Default compliance framework successfully updated',
    ),
    setDefaultError: s__('ComplianceFrameworks|Error setting the default compliance frameworks'),
  },
};
</script>
<template>
  <div>
    <gl-alert
      v-if="alertMessage"
      class="gl-mt-5 gl-mb-5"
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
      @addFramework="onClickAdd"
    />

    <gl-table-lite v-if="hasFrameworks" :items="complianceFrameworks" :fields="tableFields">
      <template #cell(name)="{ item: framework }">
        <gl-label
          :background-color="framework.color"
          :description="$options.i18n.editFramework"
          :title="framework.name"
          :target="framework.editPath"
        />
        <gl-badge
          v-if="framework.default"
          size="md"
          variant="info"
          :aria-label="$options.i18n.default"
          data-testid="compliance-framework-default-badge"
          >{{ $options.i18n.default }}</gl-badge
        >
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
          @edit="markForEdit"
          @setDefault="setDefaultFramework"
          @removeDefault="setDefaultFramework"
        />
      </template>
    </gl-table-lite>

    <gl-button
      v-if="showAddButton"
      class="gl-mt-3"
      category="secondary"
      variant="confirm"
      size="small"
      data-testid="add-framework-btn"
      :href="addFrameworkHref"
      @click="onClickAdd"
    >
      {{ $options.i18n.addBtn }}
    </gl-button>

    <form-modal
      v-if="glFeatures.manageComplianceFrameworksModalsRefactor"
      ref="formModal"
      :framework="markedForEdit"
      @change="onChange"
    />
    <delete-modal
      v-if="hasFrameworks"
      :id="markedForDeletion.id"
      ref="deleteModal"
      :name="markedForDeletion.name"
      @deleting="onDeleting"
      @delete="onDelete"
      @error="onError"
    />
  </div>
</template>
