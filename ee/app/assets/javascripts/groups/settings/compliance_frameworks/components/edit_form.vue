<script>
import * as Sentry from '@sentry/browser';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';

import { FETCH_ERROR, SAVE_ERROR } from '../constants';
import getComplianceFrameworkQuery from '../graphql/queries/get_compliance_framework.query.graphql';
import updateComplianceFrameworkMutation from '../graphql/queries/update_compliance_framework.mutation.graphql';
import { getSubmissionParams, initialiseFormData } from '../utils';
import FormStatus from './form_status.vue';
import SharedForm from './shared_form.vue';

export default {
  components: {
    FormStatus,
    SharedForm,
  },
  props: {
    graphqlFieldName: {
      type: String,
      required: true,
    },
    groupEditPath: {
      type: String,
      required: true,
    },
    groupPath: {
      type: String,
      required: true,
    },
    id: {
      type: String,
      required: false,
      default: null,
    },
    pipelineConfigurationFullPathEnabled: {
      type: Boolean,
      required: false,
      default: false,
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
        });

        const [error] = data?.updateComplianceFramework?.errors || [];

        if (error) {
          this.setSavingError(new Error(error), error);
        } else {
          visitUrl(this.groupEditPath);
        }
      } catch (e) {
        this.setSavingError(e, SAVE_ERROR);
      }
    },
  },
  i18n: {
    submitButtonText: __('Save changes'),
  },
};
</script>
<template>
  <form-status :loading="isLoading" :error="errorMessage">
    <shared-form
      v-if="showForm"
      :group-edit-path="groupEditPath"
      :pipeline-configuration-full-path-enabled="pipelineConfigurationFullPathEnabled"
      :name.sync="formData.name"
      :description.sync="formData.description"
      :pipeline-configuration-full-path.sync="formData.pipelineConfigurationFullPath"
      :color.sync="formData.color"
      :submit-button-text="$options.i18n.submitButtonText"
      @submit="onSubmit"
    />
  </form-status>
</template>
