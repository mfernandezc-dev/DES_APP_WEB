import CrudPage from '../../components/CrudPage.jsx';
import { consultaService } from '../../services/consultaService.js';
import { mascotaService } from '../../services/mascotaService.js';
import { formatCurrency, formatDate } from '../../utils/format.js';
import ConsultaForm from './ConsultaForm.jsx';

const config = {
  title: 'Consultas', singular: 'Consulta', newLabel: 'Nueva consulta', icon: 'consultations',
  description: 'Organiza la atención, el diagnóstico y el costo de cada consulta.',
  service: consultaService, Form: ConsultaForm,
  relation: { service: mascotaService, singular: 'mascota', plural: 'mascotas', article: 'una', page: 'mascotas', label: (item) => item.nombre, filter: consultaService.listarPorMascota },
  columns: [
    { key: 'id', label: 'ID de consulta', render: (record) => <span className="record-id">#{record.id}</span> },
    { key: 'idMascota', label: 'Mascota', className: 'cell-strong', render: (record, related) => related.find((item) => item.id === record.idMascota)?.nombre || `Mascota #${record.idMascota} (sin datos)` },
    { key: 'fecha', label: 'Fecha', render: (record) => formatDate(record.fecha) },
    { key: 'motivo', label: 'Motivo', className: 'cell-long' },
    { key: 'diagnostico', label: 'Diagnóstico', className: 'cell-long' },
    { key: 'costo', label: 'Costo', className: 'cell-money', render: (record) => formatCurrency(record.costo) },
  ],
};

export default function ConsultasPage() { return <CrudPage config={config} />; }
