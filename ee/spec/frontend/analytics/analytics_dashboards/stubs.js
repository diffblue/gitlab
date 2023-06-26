export const BuilderComponent = {
  data() {
    return {
      resultSet: {
        query: () => ({ foo: 'bar' }),
      },
    };
  },
  template: '<div><slot></slot></div>',
};

export const QueryBuilder = {
  data() {
    return {
      loading: false,
      filters: [],
      measures: [],
      dimensions: [],
      timeDimensions: [],
      setMeasures: () => {},
      setFilters: () => {},
      addFilters: () => {},
      addDimensions: () => {},
      removeDimensions: () => {},
      setTimeDimensions: () => {},
      removeTimeDimensions: () => {},
    };
  },
  template: `
    <builder-component>
      <slot name="builder" v-bind="{measures, dimensions, timeDimensions, setTimeDimensions, removeTimeDimensions, removeDimensions, addDimensions, filters, setMeasures, setFilters, addFilters}"></slot>
      <slot v-bind="{loading}"></slot>
    </builder-component>
  `,
};
