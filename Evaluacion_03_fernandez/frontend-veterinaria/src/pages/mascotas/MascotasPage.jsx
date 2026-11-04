import CrudPage from '../../components/CrudPage.jsx';
import { mascotaService } from '../../services/mascotaService.js';
import { propietarioService } from '../../services/propietarioService.js';
import { formatDate, fullName } from '../../utils/format.js';
import MascotaForm from './MascotaForm.jsx';

const config = {
  title: 'Mascotas', singular: 'Mascota', newLabel: 'Nueva mascota', icon: 'pets',
  description: 'Registra a cada mascota y vincúlala con su propietario.',
  service: mascotaService, Form: MascotaForm,
  relation: { service: propietarioService, singular: 'propietario', plural: 'propietarios', article: 'un', page: 'propietarios', label: fullName, filter: mascotaService.listarPorPropietario },
  columns: [
    { key: 'id', label: 'ID', render: (record) => <span className="record-id">#{record.id}</span> },
    { key: 'nombre', label: 'Nombre', className: 'cell-strong' },
    { key: 'especie', label: 'Especie', render: (record) => <span className="species-badge">{record.especie}</span> },
    { key: 'fechaNacimiento', label: 'Fecha de nacimiento', render: (record) => formatDate(record.fechaNacimiento) },
    { key: 'idPropietario', label: 'Propietario', render: (record, related) => {
      const owner = related.find((item) => item.id === record.idPropietario);
      return owner ? fullName(owner) : `Propietario #${record.idPropietario} (sin datos)`;
    } },
  ],
};

export default function MascotasPage() { return <CrudPage config={config} />; }
