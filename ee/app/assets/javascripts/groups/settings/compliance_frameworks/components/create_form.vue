<script>
import * as Sentry from '@sentry/browser';

import { visitUrl } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';

import getComplianceFrameworkQuery from 'ee/graphql_shared/queries/get_compliance_framework.query.graphql';
import { SAVE_ERROR } from '../constants';
import createComplianceFrameworkMutation from '../graphql/queries/create_compliance_framework.mutation.graphql';
import { getSubmissionParams, initialiseFormData, isModalsRefactorEnabled } from '../utils';
import FormStatus from './form_status.vue';
import SharedForm from './shared_form.vue';

export default {
  components: {
    FormStatus,
    SharedForm,
  },
  inject: ['groupEditPath', 'groupPath', 'pipelineConfigurationFullPathEnabled'],
  data() {
    return {
      errorMessage: '',
      formData: initialiseFormData(),
      saving: false,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.loading || this.saving;
    },
  },
  methods: {
    setError(error, userFriendlyText) {
      this.saving = false;
      this.errorMessage = userFriendlyText;
      Sentry.captureException(error);
    },
    onCancel() {
      if (isModalsRefactorEnabled()) {
        this.$emit('cancel');
      }
    },
    async onSubmit() {
      this.saving = true;
      this.errorMessage = '';
      try {
        const params = getSubmissionParams(
          this.formData,
          this.pipelineConfigurationFullPathEnabled,
        );

        const { data } = await this.$apollo.mutate({
          mutation: createComplianceFrameworkMutation,
          variables: {
            input: {
              namespacePath: this.groupPath,
              params,
            },
          },
          ...(isModalsRefactorEnabled()
            ? {
                awaitRefetchQueries: true,
                refetchQueries: [
                  {
                    query: getComplianceFrameworkQuery,
                    variables: {
                      fullPath: this.groupPath,
                    },
                  },
                ],
              }
            : {}),
        });

        const [error] = data?.createComplianceFramework?.errors || [];

        if (error) {
          this.setError(new Error(error), error);
        } else {
          if (!isModalsRefactorEnabled()) {
            visitUrl(this.groupEditPath);
            return;
          }

          this.$emit('success', {
            message: this.$options.i18n.successMessageText,
            framework: data.createComplianceFramework.framework,
          });
        }
      } catch (e) {
        this.setError(e, SAVE_ERROR);
      }
    },
  },
  i18n: {
    submitButtonText: s__('ComplianceFrameworks|Add framework'),
    successMessageText: s__('ComplianceFrameworks|Compliance framework created'),
  },
};
</script>
<template>
  <form-status :loading="isLoading" :error="errorMessage">
    <shared-form
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
