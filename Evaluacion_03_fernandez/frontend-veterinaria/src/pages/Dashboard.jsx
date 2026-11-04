import { useCallback, useEffect, useRef, useState } from 'react';
import Icon from '../components/Icon.jsx';
import { propietarioService } from '../services/propietarioService.js';
import { mascotaService } from '../services/mascotaService.js';
import { consultaService } from '../services/consultaService.js';

const modules = [
  { id: 'propietarios', label: 'Propietarios', icon: 'owners', service: propietarioService, description: 'Datos de contacto y responsables de las mascotas.', action: 'Gestionar propietarios' },
  { id: 'mascotas', label: 'Mascotas', icon: 'pets', service: mascotaService, description: 'Pacientes registrados y sus propietarios.', action: 'Gestionar mascotas' },
  { id: 'consultas', label: 'Consultas', icon: 'consultations', service: consultaService, description: 'Atenciones veterinarias, diagnósticos y costos.', action: 'Gestionar consultas' },
];

export default function Dashboard() {
  const [stats, setStats] = useState({});
  const [loading, setLoading] = useState(true);
  const sequence = useRef(0);
  const load = useCallback(async () => {
    const token = ++sequence.current;
    setLoading(true);
    const results = await Promise.all(modules.map(async (module) => {
      try {
        const data = await module.service.listar();
        if (!Array.isArray(data)) throw new Error('La API no devolvió una lista válida.');
        return [module.id, { count: data.length }];
      } catch (error) { return [module.id, { error: error.message }]; }
    }));
    if (token === sequence.current) { setStats(Object.fromEntries(results)); setLoading(false); }
  }, []);
  useEffect(() => { load(); return () => { sequence.current++; }; }, [load]);

  return <>
    <div className="page-heading"><div><span className="eyebrow">PANEL GENERAL</span><h1>Todo listo para cuidar mejor.</h1><p>Bienvenido al Sistema de Atención Veterinaria.</p></div><button className="button button-secondary" onClick={load} disabled={loading}><Icon name="refresh" size={17} />{loading ? 'Cargando…' : 'Actualizar totales'}</button></div>
    <section className="welcome-panel"><div><span className="welcome-label">CADA MASCOTA, UNA HISTORIA</span><h2>Una atención más cercana,<br />una gestión más sencilla.</h2><p>Propietarios, mascotas y consultas en un solo lugar.<br />Selecciona un módulo para comenzar.</p><a className="button welcome-button" href="#mascotas">Ver mascotas<Icon name="arrow" size={18} /></a></div><div className="welcome-art" aria-hidden="true"><div className="art-orbit orbit-one" /><div className="art-orbit orbit-two" /><div className="art-paw"><Icon name="pets" size={94} /></div><span className="art-plus plus-one">+</span><span className="art-plus plus-two">+</span><span className="art-dot" /></div></section>
    <div className="section-title"><h2>Resumen del sistema</h2><span>Totales obtenidos de los microservicios</span></div>
    <section className="stats-grid" aria-label="Totales de registros" aria-busy={loading}>
      {modules.map((module) => <article key={module.id} className={`stat-card theme-${module.id}`}><div className="stat-top"><span className="module-icon"><Icon name={module.icon} size={23} /></span><span className="stat-label">{module.label}</span></div><div className="stat-value">{loading ? '…' : stats[module.id]?.count ?? '—'}</div><p className="stat-caption">{loading ? 'Consultando API…' : stats[module.id]?.error ? 'No disponible' : 'registros en total'}</p>{!loading && stats[module.id]?.error && <p className="stat-error" role="alert">{stats[module.id].error}</p>}<a href={`#${module.id}`} className="stat-link">Ver {module.id}<Icon name="arrow" size={17} /></a></article>)}
    </section>
    <div className="section-title"><h2>Accesos directos</h2><span>Administra la información de cada módulo</span></div>
    <section className="shortcuts-grid" aria-label="Accesos directos">{modules.map((module) => <a href={`#${module.id}`} className={`shortcut-card theme-${module.id}`} key={module.id}><span className="module-icon"><Icon name={module.icon} size={22} /></span><div><h3>{module.action}</h3><p>{module.description}</p></div><Icon name="arrow" size={19} /></a>)}</section>
    <div className="dashboard-note"><Icon name="consultations" size={20} /><p><strong>Información conectada a tus APIs.</strong> Los registros se consultan en los puertos 8081, 8082 y 8083. Si un servicio no responde, su total se mostrará como no disponible.</p></div>
  </>;
}
