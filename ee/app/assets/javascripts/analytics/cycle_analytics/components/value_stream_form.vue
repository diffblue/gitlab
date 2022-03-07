<script>
import { mapState } from 'vuex';
import ValueStreamFormContent from './value_stream_form_content.vue';
import { generateInitialStageData } from './create_value_stream_form/utils';

export default {
  name: 'ValueStreamForm',
  components: {
    ValueStreamFormContent,
  },
  props: {
    isEditing: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapState({
      selectedValueStream: 'selectedValueStream',
      selectedValueStreamStages: 'stages',
      initialFormErrors: 'createValueStreamErrors',
      defaultStageConfig: 'defaultStageConfig',
    }),
    initialData() {
      return this.isEditing
        ? {
            ...this.selectedValueStream,
            stages: generateInitialStageData(
              this.defaultStageConfig,
              this.selectedValueStreamStages,
            ),
          }
        : {
            name: '',
            stages: [],
          };
    },
  },
};
</script>
<template>
  <value-stream-form-content
    :initial-data="initialData"
    :initial-form-errors="initialFormErrors"
    :default-stage-config="defaultStageConfig"
    :is-editing="isEditing"
    @hidden="$emit('hidden')"
  />
</template>
