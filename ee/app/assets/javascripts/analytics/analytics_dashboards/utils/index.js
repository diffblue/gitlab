export const isValidConfigFileName = (fileName) =>
  fileName.endsWith('.json') || fileName.endsWith('.yml') || fileName.endsWith('.yaml');

export const configFileNameToID = (fileName) => fileName.replace(/(\.json|\.ya?ml)$/, '');
