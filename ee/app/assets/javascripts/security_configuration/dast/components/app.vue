<script>
import DastConfigurationForm from './configuration_form.vue';
import DastConfigurationHeader from './dast_configuration_header.vue';

export default {
  name: 'DastConfigurationApp',
  components: {
    DastConfigurationForm,
    DastConfigurationHeader,
  },
  inject: ['projectPath', 'dastEnabled', 'pipelineCreatedAt', 'pipelineId', 'pipelinePath'],
};
</script>

<template>
  <div>
    <dast-configuration-header
      :dast-enabled="dastEnabled"
      :pipeline-path="pipelinePath"
      :pipeline-id="pipelineId"
      :pipeline-created-at="pipelineCreatedAt"
    />
    <dast-configuration-form />
  </div>
</template>
