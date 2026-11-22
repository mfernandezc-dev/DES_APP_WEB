const body = pm.response.json();
const pedido = Array.isArray(body) ? body.find(p => p.id === 1) : body;
pm.test('HTTP 200', () => pm.response.to.have.status(200));
pm.test('Pedido original preservado', () => {
  pm.expect(pedido.id).to.eql(1);
  pm.expect(pedido.cantidad).to.eql(1);
  pm.expect(pedido.estado).to.eql('PENDIENTE');
});
pm.test('Cliente real sin fallback', () => {
  pm.expect(pedido.cliente.id).to.eql(1);
  pm.expect(pedido.cliente.nombre).to.eql('Carlos');
  pm.expect(pedido.cliente.apellido).to.eql('Ramirez');
});
pm.test('Producto real sin fallback', () => {
  pm.expect(pedido.producto.id).to.eql(1);
  pm.expect(pedido.producto.nombre).to.eql('Laptop');
  pm.expect(pedido.producto.precio).to.eql(2500);
});
