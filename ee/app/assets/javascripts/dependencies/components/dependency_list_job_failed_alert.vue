<script>
import { GlAlert, GlSprintf } from '@gitlab/ui';
import { __, s__ } from '~/locale';

export default {
  name: 'DependencyListJobFailedAlert',
  components: {
    GlAlert,
    GlSprintf,
  },
  props: {
    jobPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    buttonProps() {
      return this.jobPath
        ? {
            secondaryButtonText: __('View job'),
            secondaryButtonLink: this.jobPath,
          }
        : {};
    },
    message() {
      return {
        text: s__(
          'Dependencies|The %{codeStartTag}dependency_scanning%{codeEndTag} job has failed and cannot generate the list. Please ensure the job is running properly and run the pipeline again.',
        ),
        placeholder: { code: ['codeStartTag', 'codeEndTag'] },
      };
    },
  },
};
</script>

<template>
  <gl-alert
    variant="danger"
    :title="s__('Dependencies|Job failed to generate the dependency list')"
    v-bind="buttonProps"
    @dismiss="$emit('close')"
    v-on="$listeners"
  >
    <span>
      <gl-sprintf :message="message.text" :placeholders="message.placeholder">
        <template #code="{ content }">
          <code>{{ content }}</code>
        </template>
      </gl-sprintf>
    </span>
  </gl-alert>
</template>
