import { fetch } from 'ee/analytics/analytics_dashboards/data_sources/value_stream';

describe('Value Stream Data Source', () => {
  let obj;

  const query = { exclude_metrics: [] };
  const queryOverrides = { exclude_metrics: ['some metric'] };
  const namespace = { name: 'cool namespace' };
  const title = 'fake title';

  describe('fetch', () => {
    it('returns an object with the fields', () => {
      obj = fetch({ namespace, title, query });

      expect(obj.namespace).toBe(namespace);
      expect(obj.title).toBe(title);
      expect(obj).toMatchObject({ exclude_metrics: [] });
    });

    it('generates a default title from the namespace if there is none', () => {
      obj = fetch({ namespace });

      expect(obj.namespace).toBe(namespace);
      expect(obj.title).toBe('Metrics comparison for cool namespace');
    });

    it('applies the queryOverrides over any relevant query parameters', () => {
      obj = fetch({ namespace, query, queryOverrides });

      expect(obj).not.toMatchObject({ exclude_metrics: [] });
      expect(obj).toMatchObject(queryOverrides);
    });
  });
});
