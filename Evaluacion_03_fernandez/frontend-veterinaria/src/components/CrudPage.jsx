import { useCallback, useEffect, useRef, useState } from 'react';
import Icon from './Icon.jsx';
import Notice from './Notice.jsx';
import ConfirmDialog from './ConfirmDialog.jsx';
import { isPositiveId } from '../utils/validation.js';

export default function CrudPage({ config }) {
  const { title, description, singular, newLabel, icon, service, columns, Form, relation } = config;
  const [records, setRecords] = useState([]);
  const [related, setRelated] = useState([]);
  const [loading, setLoading] = useState(true);
  const [relatedLoading, setRelatedLoading] = useState(Boolean(relation));
  const [listError, setListError] = useState('');
  const [relatedError, setRelatedError] = useState('');
  const [notice, setNotice] = useState('');
  const [searchId, setSearchId] = useState('');
  const [searchError, setSearchError] = useState('');
  const [filterId, setFilterId] = useState('');
  const [criteria, setCriteria] = useState({ type: 'all' });
  const [form, setForm] = useState(null);
  const [pendingDelete, setPendingDelete] = useState(null);
  const [deleting, setDeleting] = useState(false);
  const [deleteError, setDeleteError] = useState('');
  const sequence = useRef(0);
  const relationSequence = useRef(0);
  const formRef = useRef(null);

  const loadRecords = useCallback(async (selection) => {
    const token = ++sequence.current;
    setLoading(true);
    setListError('');
    try {
      let data;
      if (selection.type === 'id') data = [await service.buscarPorId(selection.value)];
      else if (selection.type === 'relation') data = await relation.filter(selection.value);
      else data = await service.listar();
      if (!Array.isArray(data) || data.some((item) => !item || item.id == null)) throw new Error('La API no devolvió una lista válida de registros.');
      if (token === sequence.current) setRecords(data);
      return true;
    } catch (error) {
      if (token === sequence.current) {
        setRecords([]);
        setListError(error.message);
      }
      return false;
    } finally {
      if (token === sequence.current) setLoading(false);
    }
  }, [service, relation]);

  const loadRelated = useCallback(async () => {
    if (!relation) return;
    const token = ++relationSequence.current;
    setRelatedLoading(true);
    setRelatedError('');
    try {
      const data = await relation.service.listar();
      if (!Array.isArray(data)) throw new Error('La API no devolvió una lista válida.');
      if (token === relationSequence.current) setRelated(data);
    } catch (error) {
      if (token === relationSequence.current) {
        setRelated([]);
        setRelatedError(`No se pudieron cargar ${relation.plural}: ${error.message}`);
      }
    } finally {
      if (token === relationSequence.current) setRelatedLoading(false);
    }
  }, [relation]);

  useEffect(() => {
    loadRecords({ type: 'all' });
    loadRelated();
    return () => { sequence.current++; relationSequence.current++; };
  }, [loadRecords, loadRelated]);

  useEffect(() => {
    if (form) formRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }, [form]);

  function showAll() {
    const all = { type: 'all' };
    setSearchId('');
    setFilterId('');
    setSearchError('');
    setCriteria(all);
    setNotice('');
    loadRecords(all);
    loadRelated();
  }

  function search(event) {
    event.preventDefault();
    if (!isPositiveId(searchId)) {
      setSearchError('Ingresa un ID entero positivo válido.');
      return;
    }
    const next = { type: 'id', value: searchId };
    setSearchError('');
    setFilterId('');
    setCriteria(next);
    setNotice('');
    loadRecords(next);
  }

  function filter(value) {
    const next = value ? { type: 'relation', value } : { type: 'all' };
    setFilterId(value);
    setSearchId('');
    setSearchError('');
    setCriteria(next);
    setNotice('');
    loadRecords(next);
  }

  async function save(payload) {
    // Si la mutación falla, EntityForm conserva el formulario y muestra el error.
    if (form.record) await service.actualizar(form.record.id, payload);
    else await service.registrar(payload);
    setNotice(`Se ${form.record ? 'actualizó' : 'registró'} correctamente el registro de ${singular.toLowerCase()}.`);
    setForm(null);
    await loadRecords(criteria);
  }

  async function remove() {
    if (deleting) return;
    setDeleting(true);
    setDeleteError('');
    try {
      await service.eliminar(pendingDelete.id);
      setPendingDelete(null);
      setNotice(`Se eliminó correctamente el registro de ${singular.toLowerCase()}.`);
      // Después de eliminar el resultado de una búsqueda, volver a todos evita un 404 innecesario.
      const next = criteria.type === 'id' ? { type: 'all' } : criteria;
      if (criteria.type === 'id') { setSearchId(''); setCriteria(next); }
      await loadRecords(next);
    } catch (error) { setDeleteError(error.message); }
    finally { setDeleting(false); }
  }

  const tableDisabled = loading || Boolean(form);
  return <>
    <div className="page-heading">
      <div><span className="eyebrow">GESTIÓN VETERINARIA</span><h1><span className="heading-icon"><Icon name={icon} size={25} /></span>{title}</h1><p>{description}</p></div>
      <button className="button button-primary" disabled={Boolean(form)} onClick={() => { setNotice(''); setForm({ record: null }); }}><Icon name="plus" size={18} />{newLabel}</button>
    </div>
    <Notice type="success">{notice}</Notice>
    <Notice>{listError && <>{listError}{notice && <span> La operación se completó, pero no fue posible actualizar la tabla. Pulsa «Actualizar».</span>}</>}</Notice>
    <Notice>{relatedError}</Notice>
    {relation && !relatedLoading && !relatedError && !related.length && <Notice type="info">No hay {relation.plural} registrados. <a href={`#${relation.page}`}>Registra {relation.article} {relation.singular}</a> para poder guardar {title.toLowerCase()}.</Notice>}
    <div ref={formRef} className="form-anchor">
      {form && <Form key={form.record?.id ?? 'new'} record={form.record} related={related} disabled={relatedLoading || Boolean(relatedError)} onSave={save} onCancel={() => setForm(null)} />}
    </div>
    <section className="panel" aria-labelledby="records-title">
      <div className="panel-heading"><div className="list-title"><h2 id="records-title">Listado de {title.toLowerCase()}</h2><span className="count-badge">{loading ? '…' : listError ? '—' : records.length}</span></div><button className="button button-secondary button-small" disabled={tableDisabled} onClick={() => { setNotice(''); loadRecords(criteria); loadRelated(); }}><Icon name="refresh" size={16} />Actualizar</button></div>
      <div className="table-toolbar">
        <form className="search-form" onSubmit={search} noValidate>
          <label htmlFor="search-id">Buscar por ID</label>
          <div className="search-row"><input id="search-id" type="number" min="1" step="1" value={searchId} onChange={(event) => setSearchId(event.target.value)} placeholder="Ej.: 1" disabled={tableDisabled} aria-invalid={Boolean(searchError)} aria-describedby={searchError ? 'search-error' : undefined} /><button className="button button-secondary" disabled={tableDisabled} type="submit"><Icon name="search" size={17} />Buscar</button></div>
          {searchError && <small className="field-error" id="search-error">{searchError}</small>}
        </form>
        {relation && <div className="filter-field"><label htmlFor="relation-filter">Filtrar por {relation.singular}</label><select id="relation-filter" value={filterId} onChange={(event) => filter(event.target.value)} disabled={tableDisabled || relatedLoading || Boolean(relatedError)}><option value="">Todos los {relation.plural}</option>{related.map((item) => <option key={item.id} value={item.id}>{relation.label(item)} · #{item.id}</option>)}</select></div>}
        <button className="button button-text show-all" onClick={showAll} disabled={tableDisabled}>Mostrar todos</button>
      </div>
      {criteria.type !== 'all' && <div className="filter-description" role="status">{criteria.type === 'id' ? `Resultado de la búsqueda: ID ${criteria.value}` : `Filtrando por ${relation.singular}: ${relation.label(related.find((item) => String(item.id) === String(criteria.value)) || { nombre: `ID ${criteria.value}`, apellido: '' })}`}</div>}
      <div className="table-container" tabIndex={0} role="region" aria-label={`Tabla de ${title.toLowerCase()}`} aria-busy={loading}>
        <table><thead><tr>{columns.map((column) => <th scope="col" key={column.key}>{column.label}</th>)}<th scope="col" className="actions-column">Acciones</th></tr></thead>
          <tbody>{loading ? <tr><td colSpan={columns.length + 1} className="empty-state" role="status"><span className="spinner" />Cargando registros…</td></tr>
            : listError ? <tr><td colSpan={columns.length + 1} className="empty-state">No fue posible cargar los registros. Revisa el mensaje de error y vuelve a intentarlo.</td></tr>
              : !records.length ? <tr><td colSpan={columns.length + 1} className="empty-state"><Icon name={icon} size={30} /><strong>No hay registros para mostrar</strong><span>{criteria.type === 'all' ? `Usa «${newLabel}» para registrar el primero.` : 'Prueba con otro filtro o muestra todos los registros.'}</span></td></tr>
                : records.map((record) => <tr key={record.id}>{columns.map((column) => <td key={column.key} className={column.className || ''}>{column.render ? column.render(record, related) : record[column.key] || '—'}</td>)}<td><div className="row-actions"><button className="icon-button edit-button" disabled={tableDisabled} aria-label={`Editar ${singular.toLowerCase()} #${record.id}`} title="Editar" onClick={() => { setNotice(''); setForm({ record }); }}><Icon name="edit" size={17} /><span>Editar</span></button><button className="icon-button delete-button" disabled={tableDisabled} aria-label={`Eliminar ${singular.toLowerCase()} #${record.id}`} title="Eliminar" onClick={() => { setDeleteError(''); setNotice(''); setPendingDelete(record); }}><Icon name="trash" size={17} /></button></div></td></tr>)}</tbody>
        </table>
      </div>
      <div className="table-footer">{loading ? 'Consultando el microservicio…' : listError ? 'Sin datos disponibles' : `${records.length} registro${records.length === 1 ? '' : 's'} ${criteria.type === 'all' ? 'en total' : 'en este resultado'}`}<span>Datos de la API · MySQL</span></div>
    </section>
    {pendingDelete && <ConfirmDialog name={`${singular.toLowerCase()} #${pendingDelete.id}${pendingDelete.nombre ? ` (${pendingDelete.nombre})` : ''}`} busy={deleting} error={deleteError} onCancel={() => setPendingDelete(null)} onConfirm={remove} />}
  </>;
}
