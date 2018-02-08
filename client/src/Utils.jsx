export const aliasForSource = (source) => source === 'VVA' ? 'VVA/LCM' : source;

export const formatDateString = (str) => {
  const date = new Date(str);

  return `${date.getMonth() + 1}/${date.getDate()}/${date.getFullYear()}`;
};
