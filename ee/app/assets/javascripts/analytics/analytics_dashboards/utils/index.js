export const isValidConfigFileName = (fileName) =>
  fileName.split('.')[0] !== '' &&
  (fileName.endsWith('.json') || fileName.endsWith('.yml') || fileName.endsWith('.yaml'));

export const configFileNameToID = (fileName) => fileName.replace(/(\.json|\.ya?ml)$/, '');
