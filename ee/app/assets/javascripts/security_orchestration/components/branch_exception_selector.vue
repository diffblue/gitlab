<script>
import { GlSprintf, GlCollapsibleListbox } from '@gitlab/ui';
import { s__ } from '~/locale';
import ProjectBranchSelector from 'ee/vue_shared/components/branches_selector/project_branch_selector.vue';
import { EXCEPTION_TYPE_ITEMS, NO_EXCEPTION_KEY, EXCEPTION_KEY } from './constants';

export default {
  EXCEPTION_TYPE_ITEMS,
  NO_EXCEPTION_KEY,
  i18n: {
    exceptionText: s__('SecurityOrchestration|with %{exceptionType} on %{branchSelector}'),
    noExceptionText: s__('SecurityOrchestration|with %{exceptionType}'),
    branchSelectorHeader: s__('SecurityOrchestration|Select exception branches'),
  },
  name: 'BranchExceptionSelector',
  components: {
    ProjectBranchSelector,
    GlCollapsibleListbox,
    GlSprintf,
  },
  inject: ['namespacePath'],
  props: {
    selectedExceptions: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      selectedExceptionType: this.selectedExceptions.length > 0 ? EXCEPTION_KEY : NO_EXCEPTION_KEY,
    };
  },
  computed: {
    exceptionText() {
      return this.selectedExceptionType === EXCEPTION_KEY
        ? this.$options.i18n.exceptionText
        : this.$options.i18n.noExceptionText;
    },
  },
  methods: {
    setExceptionType(type) {
      this.selectedExceptionType = type;
    },
    selectExceptions(value) {
      this.$emit('select', { branch_exceptions: value });
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-center gl-gap-3">
    <gl-sprintf :message="exceptionText">
      <template #exceptionType>
        <gl-collapsible-listbox
          :items="$options.EXCEPTION_TYPE_ITEMS"
          :selected="selectedExceptionType"
          @select="setExceptionType"
        />
      </template>

      <template #branchSelector>
        <project-branch-selector
          class="gl-max-w-48"
          :header="$options.i18n.branchSelectorHeader"
          :text="$options.i18n.branchSelectorHeader"
          :project-full-path="namespacePath"
          :selected="selectedExceptions"
          @select="selectExceptions"
        />
      </template>
    </gl-sprintf>
  </div>
</template>
