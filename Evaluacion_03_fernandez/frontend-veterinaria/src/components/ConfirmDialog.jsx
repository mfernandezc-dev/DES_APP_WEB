import { useEffect, useRef } from 'react';
import Icon from './Icon.jsx';
import Notice from './Notice.jsx';

export default function ConfirmDialog({ name, busy, error, onCancel, onConfirm }) {
  const ref = useRef(null);
  const cancelRef = useRef(null);
  useEffect(() => {
    const previous = document.activeElement;
    const dialog = ref.current;
    dialog.showModal();
    cancelRef.current?.focus();
    return () => { dialog.close(); previous?.focus(); };
  }, []);
  return <dialog ref={ref} className="confirm-dialog" aria-labelledby="confirm-title" aria-describedby="confirm-description" onCancel={(event) => { event.preventDefault(); if (!busy) onCancel(); }}>
    <div className="delete-icon"><Icon name="trash" size={26} /></div>
    <h2 id="confirm-title">¿Eliminar este registro?</h2>
    <p id="confirm-description">Vas a eliminar <strong>{name}</strong>. Esta acción no se puede deshacer.</p>
    <Notice>{error}</Notice>
    <div className="form-actions">
      <button ref={cancelRef} className="button button-secondary" onClick={onCancel} disabled={busy}>Cancelar</button>
      <button className="button button-danger" onClick={onConfirm} disabled={busy}>{busy ? 'Eliminando…' : 'Sí, eliminar'}</button>
    </div>
  </dialog>;
}
