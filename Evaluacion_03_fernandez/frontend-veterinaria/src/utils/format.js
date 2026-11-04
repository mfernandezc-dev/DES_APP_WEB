export function formatDate(value) {
  if (!value) return '—';
  const [year, month, day] = value.split('-');
  return `${day}/${month}/${year}`;
}

const soles = new Intl.NumberFormat('es-PE', { style: 'currency', currency: 'PEN' });
export const formatCurrency = (value) => value == null ? '—' : soles.format(Number(value));
export const fullName = (person) => `${person.nombre} ${person.apellido}`.trim();
