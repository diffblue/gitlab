<script>
import { GlFormGroup, GlIcon, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { s__ } from '~/locale';
import GenericBaseLayoutComponent from '../../generic_base_layout_component.vue';
import RunnerTagsList from './runner_tags_list.vue';

export default {
  i18n: {
    label: s__('ScanExecutionPolicy|Runner tags:'),
    selectedTagsInformation: s__(
      'ScanExecutionPolicy|A runner will be selected automatically from those available.',
    ),
    tags: s__('ScanExecutionPolicy|Tags'),
  },
  components: {
    GenericBaseLayoutComponent,
    GlFormGroup,
    GlIcon,
    RunnerTagsList,
  },
  directives: {
    GlTooltip,
  },
  inject: ['namespacePath', 'namespaceType'],
  props: {
    selected: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  methods: {
    remove() {
      this.$emit('remove');
    },
    handleSelection(values) {
      this.$emit('input', { tags: values });
    },
  },
};
</script>

<template>
  <generic-base-layout-component class="gl-w-full gl-bg-white" @remove="remove">
    <template #selector>
      <label class="gl-mb-0 gl-mr-4" :title="$options.i18n.label">{{ $options.i18n.label }}</label>
    </template>
    <template #content>
      <gl-form-group
        class="gl-mb-0"
        :label="$options.i18n.tags"
        label-for="policy-tags"
        label-sr-only
      >
        <div class="gl-display-flex gl-align-items-center">
          <runner-tags-list
            id="policy-tags"
            :value="selected"
            :namespace-path="namespacePath"
            :namespace-type="namespaceType"
            @error="$emit('error')"
            @input="handleSelection"
          />
          <gl-icon
            v-gl-tooltip
            name="question-o"
            :title="$options.i18n.selectedTagsInformation"
            class="gl-text-blue-600 gl-ml-2"
          />
        </div>
      </gl-form-group>
    </template>
  </generic-base-layout-component>
</template>
