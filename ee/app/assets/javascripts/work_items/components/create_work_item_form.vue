<script>
import { GlAlert, GlButton, GlForm, GlFormCheckbox, GlFormGroup, GlFormInput } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import createWorkItemMutation from '~/work_items/graphql/create_work_item.mutation.graphql';
import groupWorkItemTypesQuery from '~/work_items/graphql/group_work_item_types.query.graphql';
import projectWorkItemTypesQuery from '~/work_items/graphql/project_work_item_types.query.graphql';
import {
  I18N_WORK_ITEM_CONFIDENTIALITY_CHECKBOX_LABEL,
  I18N_WORK_ITEM_CREATE_BUTTON_LABEL,
  I18N_WORK_ITEM_ERROR_CREATING,
  I18N_WORK_ITEM_ERROR_FETCHING_TYPES,
  sprintfWorkItem,
} from '~/work_items/constants';

export default {
  components: {
    GlAlert,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormCheckbox,
    GlButton,
  },
  inject: ['fullPath'],
  props: {
    isGroup: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemType: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      title: '',
      error: null,
      loading: false,
      confidential: false,
      workItemTypes: [],
    };
  },
  apollo: {
    workItemTypes: {
      query() {
        return this.isGroup ? groupWorkItemTypesQuery : projectWorkItemTypesQuery;
      },
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update(data) {
        return data.workspace?.workItemTypes?.nodes || [];
      },
      error() {
        this.error = I18N_WORK_ITEM_ERROR_FETCHING_TYPES;
      },
    },
  },
  computed: {
    checkboxText() {
      return sprintfWorkItem(I18N_WORK_ITEM_CONFIDENTIALITY_CHECKBOX_LABEL, this.workItemType);
    },
    createButtonText() {
      return sprintfWorkItem(I18N_WORK_ITEM_CREATE_BUTTON_LABEL, this.workItemType);
    },
    createErrorText() {
      return sprintfWorkItem(I18N_WORK_ITEM_ERROR_CREATING, this.workItemType);
    },
    isButtonDisabled() {
      return this.title.length === 0;
    },
    workItemTypeId() {
      return this.workItemTypes.find((type) => type.name === this.workItemType)?.id;
    },
  },
  methods: {
    async createWorkItem() {
      this.loading = true;

      try {
        const { data } = await this.$apollo.mutate({
          mutation: createWorkItemMutation,
          variables: {
            input: {
              title: this.title,
              namespacePath: this.fullPath,
              workItemTypeId: this.workItemTypeId,
              confidential: this.confidential,
            },
          },
        });

        const { workItem, errors } = data.workItemCreate;

        if (errors.length) {
          throw new Error(errors);
        }

        this.$emit('created', { workItem });
        this.resetForm();
      } catch (error) {
        this.error = error.message || this.createErrorText;
        Sentry.captureException(error);
      }

      this.loading = false;
    },
    handleCancelClick() {
      this.resetForm();
      this.$emit('hide');
    },
    resetForm() {
      this.title = '';
    },
  },
};
</script>
<template>
  <div>
    <gl-alert v-if="error" variant="danger" @dismiss="error = null">{{ error }}</gl-alert>

    <gl-form
      class="gl-md-display-flex gl-align-items-flex-start gl-gap-3 gl-border-b gl-border-gray-50 gl-p-5"
      @submit.prevent="createWorkItem"
    >
      <div class="gl-flex-grow-1 gl-mb-3 gl-md-mb-0">
        <gl-form-group :label="__('Title')" label-for="work-item-title" label-sr-only>
          <gl-form-input
            id="work-item-title"
            v-model.trim="title"
            autofocus
            :placeholder="__('Title')"
          />
        </gl-form-group>
        <gl-form-checkbox v-model="confidential">
          {{ checkboxText }}
        </gl-form-checkbox>
      </div>
      <gl-button type="submit" :disabled="isButtonDisabled" :loading="loading" variant="confirm">
        {{ createButtonText }}
      </gl-button>
      <gl-button @click="handleCancelClick">
        {{ __('Cancel') }}
      </gl-button>
    </gl-form>
  </div>
</template>
