/**
 * Extract unique list of tags from list of edges having
 * node as direct child and possible duplicates among tagLists
 * @param nodes
 * @returns {string[]}
 */
export const getUniqueTagListFromEdges = (nodes) => {
  const tags = nodes.map((node) => node?.tagList).flat();

  return Array.from(new Set(tags));
};
