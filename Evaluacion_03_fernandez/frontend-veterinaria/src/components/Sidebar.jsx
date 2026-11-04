import Icon from './Icon.jsx';

export const navigation = [
  { id: 'inicio', label: 'Inicio', icon: 'home' },
  { id: 'propietarios', label: 'Propietarios', icon: 'owners' },
  { id: 'mascotas', label: 'Mascotas', icon: 'pets' },
  { id: 'consultas', label: 'Consultas', icon: 'consultations' },
];

export default function Sidebar({ current }) {
  return <aside className="sidebar">
    <a className="brand" href="#inicio" aria-label="Veterinaria, ir a inicio">
      <span className="brand-icon"><Icon name="pets" size={25} /></span>
      <span>Veterinaria<small>Sistema de atención</small></span>
    </a>
    <div className="nav-caption">MENÚ PRINCIPAL</div>
    <nav aria-label="Navegación principal">
      {navigation.map((item) => <a key={item.id} href={`#${item.id}`} className={`nav-link ${current === item.id ? 'active' : ''}`} aria-current={current === item.id ? 'page' : undefined}>
        <Icon name={item.icon} /><span>{item.label}</span>
      </a>)}
    </nav>
    <div className="sidebar-note"><Icon name="pets" size={28} /><strong>Cuidamos cada vínculo</strong><p>Una atención organizada para quienes más quieres.</p></div>
    <footer className="sidebar-footer">Desarrollo de Aplicaciones Web<br /><strong>Evaluación N.º 03</strong></footer>
  </aside>;
}
