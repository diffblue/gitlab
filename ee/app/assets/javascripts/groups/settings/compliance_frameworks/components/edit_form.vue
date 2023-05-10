<script>
import * as Sentry from '@sentry/browser';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { __, s__ } from '~/locale';

import getComplianceFrameworkQuery from 'ee/graphql_shared/queries/get_compliance_framework.query.graphql';
import { FETCH_ERROR, SAVE_ERROR } from '../constants';
import updateComplianceFrameworkMutation from '../graphql/queries/update_compliance_framework.mutation.graphql';
import { getSubmissionParams, initialiseFormData } from '../utils';
import FormStatus from './form_status.vue';
import SharedForm from './shared_form.vue';

export default {
  components: {
    FormStatus,
    SharedForm,
  },
  inject: {
    graphqlFieldName: {
      default: '',
    },
    groupPath: 'groupPath',
    pipelineConfigurationFullPathEnabled: 'pipelineConfigurationFullPathEnabled',
  },
  props: {
    id: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      initErrorMessage: '',
      saveErrorMessage: '',
      formData: initialiseFormData(),
      saving: false,
    };
  },
  apollo: {
    namespace: {
      query: getComplianceFrameworkQuery,
      variables() {
        return {
          fullPath: this.groupPath,
          complianceFramework: this.graphqlId,
        };
      },
      result({ data }) {
        if (!data) {
          return;
        }
        this.formData = this.extractComplianceFramework(data);
      },
      error(error) {
        this.setInitError(error, FETCH_ERROR);
      },
    },
  },
  computed: {
    graphqlId() {
      return convertToGraphQLId(this.graphqlFieldName, this.id);
    },
    isLoading() {
      return this.$apollo.loading || this.saving;
    },
    showForm() {
      return (
        Object.values(this.formData).filter((d) => d !== null).length > 0 && !this.initErrorMessage
      );
    },
    errorMessage() {
      return this.initErrorMessage || this.saveErrorMessage;
    },
  },
  methods: {
    extractComplianceFramework(data) {
      const complianceFrameworks = data.namespace?.complianceFrameworks?.nodes || [];

      if (!complianceFrameworks.length) {
        this.setInitError(new Error(FETCH_ERROR), FETCH_ERROR);

        return initialiseFormData();
      }

      const { name, description, pipelineConfigurationFullPath, color } = complianceFrameworks[0];

      return {
        name,
        description,
        pipelineConfigurationFullPath,
        color,
      };
    },
    setInitError(error, userFriendlyText) {
      this.initErrorMessage = userFriendlyText;
      Sentry.captureException(error);
    },
    setSavingError(error, userFriendlyText) {
      this.saving = false;
      this.saveErrorMessage = userFriendlyText;
      Sentry.captureException(error);
    },
    onCancel() {
      this.$emit('cancel');
    },
    async onSubmit() {
      this.saving = true;
      this.saveErrorMessage = '';

      try {
        const params = getSubmissionParams(
          this.formData,
          this.pipelineConfigurationFullPathEnabled,
        );
        const { data } = await this.$apollo.mutate({
          mutation: updateComplianceFrameworkMutation,
          variables: {
            input: {
              id: this.graphqlId,
              params,
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
          this.setSavingError(new Error(error), error);
        } else {
          this.$emit('success', {
            message: this.$options.i18n.successMessageText,
            framework: data.updateComplianceFramework.framework,
          });
        }
      } catch (e) {
        this.setSavingError(e, SAVE_ERROR);
      }
    },
  },
  i18n: {
    submitButtonText: __('Save changes'),
    successMessageText: s__('ComplianceFrameworks|Saved changes to compliance framework'),
  },
};
</script>
<template>
  <form-status :loading="isLoading" :error="errorMessage">
    <shared-form
      v-if="showForm"
      :name.sync="formData.name"
      :description.sync="formData.description"
      :pipeline-configuration-full-path.sync="formData.pipelineConfigurationFullPath"
      :color.sync="formData.color"
      :submit-button-text="$options.i18n.submitButtonText"
      @cancel="onCancel"
      @submit="onSubmit"
    />
  </form-status>
</template>
