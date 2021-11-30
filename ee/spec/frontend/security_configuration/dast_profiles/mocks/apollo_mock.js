export const dastSiteValidations = (nodes = []) => ({
  data: {
    project: {
      id: '1',
      validations: {
        nodes,
      },
    },
  },
});
