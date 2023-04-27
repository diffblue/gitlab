<script>
import { WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import { __ } from '~/locale';
import { unit } from '../constants';
import summaryStatsQuery from '../graphql/iteration_issues_summary.query.graphql';

export default {
  apollo: {
    issues: {
      query: summaryStatsQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return {
          open: data[this.namespaceType]?.openIssues?.[this.displayValue] || 0,
          assigned: data[this.namespaceType]?.assignedIssues?.[this.displayValue] || 0,
          closed: data[this.namespaceType]?.closedIssues?.[this.displayValue] || 0,
        };
      },
      error() {
        this.error = __('Error loading issues');
      },
    },
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    iterationId: {
      type: String,
      required: true,
    },
    namespaceType: {
      type: String,
      required: false,
      default: WORKSPACE_GROUP,
      validator: (value) => [WORKSPACE_GROUP, WORKSPACE_PROJECT].includes(value),
    },
    displayValue: {
      type: String,
      required: false,
      default: unit.count,
      validator: (val) => unit[val],
    },
  },
  data() {
    return {
      issues: {
        assigned: 0,
        open: 0,
        closed: 0,
      },
    };
  },
  computed: {
    queryVariables() {
      return {
        fullPath: this.fullPath,
        id: this.iterationId,
        isGroup: this.namespaceType === WORKSPACE_GROUP,
        weight: this.displayValue === unit.weight,
      };
    },
    columns() {
      return [
        {
          title: __('Completed'),
          value: this.issues.closed,
        },
        {
          title: __('Incomplete'),
          value: this.issues.assigned,
        },
        {
          title: __('Unstarted'),
          value: this.issues.open,
        },
      ];
    },
    total() {
      return this.issues.open + this.issues.assigned + this.issues.closed;
    },
  },
  methods: {
    percent(val) {
      if (!this.total) return 0;
      return ((val / this.total) * 100).toFixed(0);
    },
  },
  render() {
    return this.$scopedSlots.default({
      columns: this.columns,
      loading: this.$apollo.queries.issues.loading,
      total: this.total,
    });
  },
};
</script>
