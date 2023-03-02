<script>
import RelatedIssuableInput from '~/related_issues/components/related_issuable_input.vue';
import { TYPE_MERGE_REQUEST } from '~/issues/constants';

export default {
  TYPE_MERGE_REQUEST,
  components: {
    RelatedIssuableInput,
  },
  props: {
    existingRefs: {
      type: Array,
      required: false,
      default: () => [],
    },
    containsHiddenBlockingMrs: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      references: this.existingRefs,
      inputValue: '',
      shouldRemoveHiddenBlockingMrs: false,
      hasFieldBeenTouched: false,
    };
  },
  methods: {
    onAddIssuable({ untouchedRawReferences, touchedReference }) {
      this.hasFieldBeenTouched = true;
      this.setReferences(this.references.concat(untouchedRawReferences));
      this.inputValue = touchedReference;
    },
    onPendingIssuableRemoveRequest(index) {
      this.references.splice(index, 1);
    },
    setReferences(refs) {
      // Remove duplicates but retain order.
      // If you don't do this, Vue will be confused by duplicates and refuse to delete them all.
      this.references = refs.filter((ref, idx) => refs.indexOf(ref) === idx);
    },
    removeReference(idToRemove) {
      this.hasFieldBeenTouched = true;
      // With this `if` statement we should only ever have to actually check the `includes` statement once.
      if (
        this.containsHiddenBlockingMrs &&
        !this.shouldRemoveHiddenBlockingMrs &&
        this.references[idToRemove].isHiddenRef
      ) {
        this.shouldRemoveHiddenBlockingMrs = true;
      }

      this.references.splice(idToRemove, 1);
    },
    onBlur(val) {
      if (val) {
        this.setReferences(this.references.concat(val));
        this.inputValue = '';
      }
    },
  },
};
</script>

<template>
  <div>
    <related-issuable-input
      path-id-separator="!"
      input-id="merge_request_blocking_merge_request_references"
      :references="references"
      :input-value="inputValue"
      :issuable-type="$options.TYPE_MERGE_REQUEST"
      @addIssuableFormInput="onAddIssuable"
      @pendingIssuableRemoveRequest="removeReference"
      @addIssuableFormBlur="onBlur"
    />
    <input
      v-for="ref in references"
      :key="ref"
      :value="ref"
      type="hidden"
      name="merge_request[blocking_merge_request_references][]"
    />
    <input
      v-if="containsHiddenBlockingMrs"
      type="hidden"
      name="merge_request[remove_hidden_blocking_merge_requests]"
      :value="shouldRemoveHiddenBlockingMrs"
    />
    <input
      type="hidden"
      name="merge_request[update_blocking_merge_request_refs]"
      :value="hasFieldBeenTouched"
    />
  </div>
</template>
