'use strict';
const $ = id => document.getElementById(id);
const API = '/api/habitaciones';
let habitaciones = [], pisos = [], csrfToken = null, csrfHeader = 'X-CSRF-TOKEN';

function mensaje(texto, error = false) {
  $('mensaje').textContent = texto;
  $('mensaje').classList.toggle('error', error);
}
function opcion(texto, valor) { const o = document.createElement('option'); o.textContent = texto; o.value = valor; return o; }
function pendiente(h) { return !h.piso || h.capacidad == null || !h.estadoOperativo; }

async function solicitud(url, method = 'GET', data) {
  const headers = {};
  if (data !== undefined) headers['Content-Type'] = 'application/json';
  if (csrfToken && !['GET','HEAD'].includes(method)) headers[csrfHeader] = csrfToken;
  const r = await fetch(url, {method, credentials:'same-origin', headers, body:data !== undefined ? JSON.stringify(data) : undefined});
  if (r.status === 401) { location.href = '/login.html'; throw Error('La sesión terminó. Inicia sesión de nuevo.'); }
  if (r.status === 403) throw Error('Operación rechazada: comprueba tus permisos o vuelve a iniciar sesión.');
  if (!r.ok) {
    const error = await r.json().catch(() => ({}));
    throw Error(error.detail || error.message || ('Error HTTP ' + r.status));
  }
  if (r.status === 204 || url === '/logout') return null;
  return r.json();
}

function renderPisos() {
  const seleccionado = $('piso').value;
  $('piso').replaceChildren(opcion(pisos.length ? 'Selecciona el piso' : 'No hay pisos registrados', ''));
  pisos.forEach(p => $('piso').append(opcion(p.nombre, String(p.id))));
  if (pisos.some(p => String(p.id) === seleccionado)) $('piso').value = seleccionado;
  $('piso-help').hidden = pisos.length > 0;
  $('save-room').disabled = pisos.length === 0;
  const tabla = $('tabla-pisos');
  tabla.replaceChildren();
  pisos.forEach(p => {
    const tr = document.createElement('tr');
    celda(tr, p.nombre);
    acciones(tr, () => editarPiso(p), () => eliminarPiso(p));
    tabla.append(tr);
  });
  if (!pisos.length) vacio(tabla, 2, 'Registra el primer piso para poder asignar habitaciones.');
}
function celda(tr, valor) { const td = document.createElement('td'); td.textContent = valor; tr.append(td); }
function acciones(tr, editar, eliminar) {
  const td = document.createElement('td'); const wrap = document.createElement('div'); wrap.className = 'row-actions';
  for (const [texto, handler, clase] of [['Editar', editar, ''], ['Eliminar', eliminar, 'danger']]) {
    const b = document.createElement('button'); b.type = 'button'; b.textContent = texto; b.className = clase;
    b.addEventListener('click', handler); wrap.append(b);
  }
  td.append(wrap); tr.append(td);
}
function vacio(tabla, columnas, texto) {
  const tr = document.createElement('tr'); const td = document.createElement('td'); td.colSpan = columnas; td.textContent = texto; tr.append(td); tabla.append(tr);
}
function renderHabitaciones() {
  $('total').textContent = habitaciones.length;
  $('plazas').textContent = habitaciones.reduce((sum,h) => sum + (h.capacidad || 0), 0);
  $('mantenimiento').textContent = habitaciones.filter(h => h.estadoOperativo === 'MANTENIMIENTO').length;
  $('pendientes').textContent = habitaciones.filter(pendiente).length;
  $('legacy-note').hidden = !habitaciones.some(pendiente);
  const tabla = $('tabla'); tabla.replaceChildren();
  habitaciones.forEach(h => {
    const tr = document.createElement('tr');
    [h.numero, h.tipo, h.capacidad ?? 'Por configurar', h.piso?.nombre ?? 'Sin asignar',
      new Intl.NumberFormat('es-EC',{style:'currency',currency:'USD'}).format(h.precio),
      h.estadoOperativo === 'HABILITADA' ? 'Habilitada' : h.estadoOperativo === 'MANTENIMIENTO' ? 'Mantenimiento' : 'Por configurar',
      h.disponible ? 'Disponible' : 'Ocupada'].forEach(v => celda(tr,v));
    acciones(tr, () => editarHabitacion(h.id), () => eliminarHabitacion(h));
    tabla.append(tr);
  });
  if (!habitaciones.length) vacio(tabla, 8, 'No hay habitaciones registradas.');
}
async function cargar() {
  const datos = await Promise.all([solicitud('/api/pisos'), solicitud(API)]);
  pisos = datos[0]; habitaciones = datos[1]; renderPisos(); renderHabitaciones();
}
function limpiar() {
  $('formulario').reset(); $('id').value = ''; $('save-room').textContent = 'Guardar habitación';
  [...$('tipo').querySelectorAll('option[data-legacy]')].forEach(o => o.remove());
}
function limpiarPiso() { $('form-piso').reset(); $('piso-id').value = ''; $('save-floor').textContent = 'Guardar piso'; }

async function editarHabitacion(id) {
  try {
    const h = await solicitud(API + '/' + id);
    limpiar();
    $('id').value = h.id; $('numero').value = h.numero;
    if (![...$('tipo').options].some(o => o.value === h.tipo)) {
      const o = opcion(h.tipo,h.tipo); o.dataset.legacy = 'true'; $('tipo').append(o);
    }
    $('tipo').value = h.tipo; $('precio').value = h.precio;
    $('capacidad').value = h.capacidad ?? ''; $('piso').value = h.piso ? String(h.piso.id) : '';
    $('estadoOperativo').value = h.estadoOperativo ?? ''; $('disponible').value = String(h.disponible);
    $('save-room').textContent = 'Guardar cambios';
    $('habitaciones').scrollIntoView({behavior:'smooth'}); $('numero').focus({preventScroll:true});
  } catch(e) { mensaje(e.message,true); }
}
async function eliminarHabitacion(h) {
  if (!confirm('¿Eliminar la habitación ' + h.numero + '?')) return;
  try {
    await solicitud(API + '/' + h.id, 'DELETE');
    if ($('id').value === String(h.id)) limpiar();
    await cargar(); mensaje('Habitación eliminada.');
  } catch(e) { mensaje(e.message,true); }
}
function editarPiso(p) {
  $('piso-id').value = p.id; $('piso-nombre').value = p.nombre; $('save-floor').textContent = 'Guardar cambios';
  $('pisos').scrollIntoView({behavior:'smooth'}); $('piso-nombre').focus({preventScroll:true});
}
async function eliminarPiso(p) {
  if (!confirm('¿Eliminar el piso “' + p.nombre + '”?')) return;
  try {
    await solicitud('/api/pisos/' + p.id,'DELETE');
    if ($('piso-id').value === String(p.id)) limpiarPiso();
    await cargar(); mensaje('Piso eliminado.');
  } catch(e) { mensaje(e.message,true); }
}

$('formulario').addEventListener('submit', async e => {
  e.preventDefault();
  const id = $('id').value;
  const datos = {
    numero:Number($('numero').value), tipo:$('tipo').value, precio:Number($('precio').value),
    disponible:$('disponible').value === 'true', capacidad:Number($('capacidad').value),
    pisoId:Number($('piso').value), estadoOperativo:$('estadoOperativo').value
  };
  $('save-room').disabled = true;
  try {
    await solicitud(id ? API + '/' + id : API, id ? 'PUT' : 'POST', datos);
    limpiar(); await cargar(); mensaje(id ? 'Habitación actualizada.' : 'Habitación creada.');
  } catch(e) { mensaje(e.message,true); }
  finally { $('save-room').disabled = pisos.length === 0; }
});
$('form-piso').addEventListener('submit', async e => {
  e.preventDefault(); const id = $('piso-id').value; $('save-floor').disabled = true;
  try {
    await solicitud(id ? '/api/pisos/' + id : '/api/pisos', id ? 'PUT' : 'POST', {nombre:$('piso-nombre').value});
    limpiarPiso(); await cargar(); mensaje(id ? 'Piso actualizado.' : 'Piso creado; ya aparece en el selector de habitaciones.');
  } catch(e) { mensaje(e.message,true); }
  finally { $('save-floor').disabled = false; }
});
$('refresh').addEventListener('click', () => cargar().then(() => mensaje('Datos actualizados.')).catch(e => mensaje(e.message,true)));
$('cancel-room').addEventListener('click',limpiar);
$('cancel-floor').addEventListener('click',limpiarPiso);
$('logout').addEventListener('click',async () => {
  try { await solicitud('/logout','POST'); location.href='/login.html?logout'; }
  catch(e) { mensaje(e.message,true); }
});
async function iniciar() {
  try {
    const token = await solicitud('/api/csrf'); csrfToken = token.token; csrfHeader = token.headerName;
    await cargar();
  } catch(e) { mensaje(e.message,true); }
}
iniciar();
