<script>
import { GlButton, GlSprintf } from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';

const BRANCH_EXCEPTIONS_MAX_LIST = 5;

export default {
  name: 'BranchExceptionsToggleList',
  components: {
    GlButton,
    GlSprintf,
  },
  props: {
    branchExceptions: {
      type: Array,
      required: true,
      validator: (exceptions) =>
        exceptions.length && exceptions.every((exception) => typeof exception === 'string'),
    },
    bulletStyle: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      visibleBranchIndex: BRANCH_EXCEPTIONS_MAX_LIST,
    };
  },
  computed: {
    branchExceptionsButtonText() {
      if (this.isBranchExceptionInitialState) {
        const hiddenBranchesLength = this.branchExceptions.length - BRANCH_EXCEPTIONS_MAX_LIST;

        return sprintf(__('+ %{hiddenBranchesLength} more'), {
          hiddenBranchesLength,
        });
      }

      return s__('SecurityOrchestration|Hide extra branches');
    },
    isBranchExceptionInitialState() {
      return this.visibleBranchIndex === BRANCH_EXCEPTIONS_MAX_LIST;
    },
    initialExceptionList() {
      return this.branchExceptions.slice(0, this.visibleBranchIndex);
    },
    showExceptionsButton() {
      return this.branchExceptions.length > BRANCH_EXCEPTIONS_MAX_LIST;
    },
  },
  methods: {
    toggleBranchExceptionLength() {
      this.visibleBranchIndex = this.isBranchExceptionInitialState
        ? this.branchExceptions.length
        : BRANCH_EXCEPTIONS_MAX_LIST;
    },
  },
};
</script>

<template>
  <div>
    <ul data-testid="exception-list" class="gl-m-0" :class="{ 'gl-list-style-none': !bulletStyle }">
      <li
        v-for="(exception, exceptionIdx) in initialExceptionList"
        :key="exceptionIdx"
        data-testid="branch-item"
        class="gl-mt-2"
      >
        <gl-sprintf :message="exception">
          <template #code="{ content }">
            <code>{{ content }}</code>
          </template>
        </gl-sprintf>
      </li>
    </ul>
    <gl-button
      v-if="showExceptionsButton"
      class="gl-ml-6 gl-mt-2"
      category="tertiary"
      variant="link"
      @click="toggleBranchExceptionLength"
    >
      {{ branchExceptionsButtonText }}
    </gl-button>
  </div>
</template>
