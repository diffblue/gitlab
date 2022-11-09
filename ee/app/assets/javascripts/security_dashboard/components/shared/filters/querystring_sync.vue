<script>
import { uniq, isEqual, omit } from 'lodash';

export default {
  props: {
    querystringKey: {
      type: String,
      required: true,
    },
    value: {
      type: Array,
      required: true,
    },
    validValues: {
      type: Array,
      required: false,
      default: null,
    },
  },
  computed: {
    rawQuerystringIds() {
      const ids = this.$route.query[this.querystringKey] || [];
      return Array.isArray(ids) ? ids : ids.split(',');
    },
    querystringIds() {
      return this.cleanUpIds(this.rawQuerystringIds);
    },
    validIds() {
      return new Set(this.validValues);
    },
  },
  watch: {
    value() {
      const ids = this.cleanUpIds(this.value);
      // To prevent a console error, don't update the querystring if the IDs are the same as the
      // existing querystring.
      if (isEqual(ids, this.querystringIds)) {
        return;
      }

      this.$router.push({ query: this.getQuerystringObject(ids) });
    },
  },
  created() {
    // Clean up the querystring if they're not in the right format or if there were no valid IDs.
    if (
      !isEqual(this.querystringIds, this.rawQuerystringIds) ||
      (Object.hasOwn(this.$route.query, this.querystringKey) && !this.querystringIds.length)
    ) {
      this.$router.replace({ query: this.getQuerystringObject(this.querystringIds) });
    }

    this.emitQuerystringIds();
    // When the user clicks the forward/back browser buttons, emit the input event.
    window.addEventListener('popstate', this.emitQuerystringIds);
  },
  destroyed() {
    window.removeEventListener('popstate', this.emitQuerystringIds);
  },
  methods: {
    emitQuerystringIds() {
      this.$emit('input', this.querystringIds);
    },
    cleanUpIds(ids) {
      // Trim each ID, remove empty string and undefined entries, remove duplicate IDs, filter by
      // valid IDs if applicable, and sort the IDs so that the isEqual() check in the watcher will
      // work properly if the IDs are in a different order.
      return uniq(
        ids
          .map((id) => id?.toString().trim())
          .filter((id) => Boolean(id) && (this.validIds.size ? this.validIds.has(id) : true))
          .sort(),
      );
    },
    getQuerystringObject(ids) {
      // If there are no IDs, remove the querystring key altogether.
      return ids.length
        ? { ...this.$route.query, [this.querystringKey]: ids.join(',') }
        : omit(this.$route.query, this.querystringKey);
    },
  },
  render() {
    return this.$scopedSlots.default?.();
  },
};
</script>
