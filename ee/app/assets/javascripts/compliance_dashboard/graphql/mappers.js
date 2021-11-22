export const mapResponse = (response) => {
  return response.map((item) => {
    return {
      ...item,
      mergedAt: item.mergeRequest.mergedAt,
    };
  });
};
