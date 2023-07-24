import listModule from './modules/list';

export const addListType = (store, listType) => {
  const { initialState, namespace } = listType;
  store.registerModule(namespace, listModule());
  store.dispatch('addListType', listType);
  store.dispatch(`${namespace}/setInitialState`, initialState);
};

export const extractGroupNamespace = (endpoint) => {
  const match = endpoint.match(/groups\/(.*)\/-\/dependencies.json/);
  return match ? match[1] : '';
};

export const filterPathBySearchTerm = (data = [], searchTerm = '') => {
  if (!searchTerm?.length) return data;

  return data.filter((item) => item.location.path.toLowerCase().includes(searchTerm.toLowerCase()));
};
