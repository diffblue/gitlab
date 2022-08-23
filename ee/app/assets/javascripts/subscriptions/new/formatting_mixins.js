import dateFormat from '~/lib/dateformat';

export default {
  methods: {
    formatAmount(amount, show) {
      return show ? `$${(Math.round(amount * 100) / 100).toLocaleString()}` : '-';
    },
    formatDate(date) {
      return dateFormat(date, 'mmm d, yyyy');
    },
  },
};
