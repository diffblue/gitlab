<script>
import { GlIcon, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { s__ } from '~/locale';
import SectionLayout from 'ee/security_orchestration/components/policy_editor/section_layout.vue';
import RunnerTagsList from './runner_tags_list.vue';

export default {
  i18n: {
    label: s__('ScanExecutionPolicy|Runner tags:'),
    selectedTagsInformation: s__(
      'ScanExecutionPolicy|A runner will be selected automatically from those available.',
    ),
  },
  components: {
    SectionLayout,
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
    handleSelection(values) {
      if (!values.length) {
        this.$emit('remove');
      } else {
        this.$emit('input', { tags: values });
      }
    },
  },
};
</script>

<template>
  <section-layout class="gl-w-full gl-bg-white" :show-remove-button="false">
    <template #selector>
      <label class="gl-mb-0 gl-mr-4" for="policy-tags" :title="$options.i18n.label">
        {{ $options.i18n.label }}
      </label>
    </template>
    <template #content>
      <div class="gl-display-flex gl-align-items-center">
        <runner-tags-list
          id="policy-tags"
          :selected-tags="selected"
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
    </template>
  </section-layout>
</template>
