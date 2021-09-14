<script>
import { GlAlert } from '@gitlab/ui';
import { __, sprintf, s__ } from '~/locale';

export default {
  name: 'DependencyListJobFailedAlert',
  components: {
    GlAlert,
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
  },
  message: sprintf(
    s__(
      'Dependencies|The %{codeStartTag}dependency_scanning%{codeEndTag} job has failed and cannot generate the list. Please ensure the job is running properly and run the pipeline again.',
    ),
    { codeStartTag: '<code>', codeEndTag: '</code>' },
    false,
  ),
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
    <span v-html="$options.message /* eslint-disable-line vue/no-v-html */"></span>
  </gl-alert>
</template>
