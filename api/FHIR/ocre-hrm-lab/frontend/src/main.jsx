import React, { useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';
import './style.css';

async function api(path, body) {
  const response = await fetch('/api' + path, {
    method: body ? 'POST' : 'GET',
    headers: body ? { 'Content-Type': 'application/json' } : {},
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!response.ok) throw new Error(`${response.status}: ${await response.text()}`);
  return response.json();
}

function App() {
  const [physicianId, setPhysicianId] = useState('P100');
  const [reportCode, setReportCode] = useState('18842-5');
  const [subscriptions, setSubscriptions] = useState([]);
  const [reports, setReports] = useState([]);
  const [deliveries, setDeliveries] = useState([]);
  const [selected, setSelected] = useState('');
  const [message, setMessage] = useState('');
  async function refresh() {
    try {
      const [s, r, d] = await Promise.all([api('/subscriptions'), api('/reports'), api('/deliveries')]);
      setSubscriptions(s); setReports(r); setDeliveries(d);
    } catch (e) { setMessage(e.message); }
  }
  useEffect(() => { refresh(); const t = setInterval(refresh, 2500); return () => clearInterval(t); }, []);
  async function create() {
    try { await api('/subscriptions', { physicianId, reportCode }); setMessage('Subscription preference saved. Send a matching ORU report.'); refresh(); }
    catch(e) { setMessage(e.message); }
  }
  async function show(path) {
    try { const response = await fetch('/api' + path); if (!response.ok) throw new Error(await response.text()); setSelected(JSON.stringify(await response.json(), null, 2)); }
    catch(e) { setMessage(e.message); }
  }
  return <main>
    <header><div className="eyebrow">Healthcare Integration Engineering Lab</div><h1>OCRE / HRM Modernization</h1><p>HL7 v2 → Mirth → Spring Boot → HAPI FHIR → RabbitMQ → physician preference matching</p><span className="tag">Local synthetic data only • Not Ontario Health-connected</span></header>
    <section className="cards">
      <article><small>Reports received</small><strong>{reports.length}</strong></article>
      <article><small>Subscriptions created</small><strong>{subscriptions.length}</strong></article>
      <article><small>Simulated matches</small><strong>{deliveries.length}</strong></article>
    </section>
    <section className="panel"><h2>Create physician subscription</h2><p>Demo-specific topic filters are serialized into a FHIR R4 Subscription with backport extensions.</p>
      <div className="form"><label>Physician ID<input value={physicianId} onChange={e=>setPhysicianId(e.target.value)} /></label><label>LOINC report code<input value={reportCode} onChange={e=>setReportCode(e.target.value)} /></label><button onClick={create} disabled={!physicianId || !reportCode}>Create preference</button></div>
      <p className="hint">Try P100 / 18842-5 first. A * in the report-code field matches all codes in this simulator.</p>
      {message && <p role="status" className="info">{message}</p>}
    </section>
    <div className="columns"><section className="panel"><h2>Subscriptions</h2>{subscriptions.length===0 && <p>No subscriptions yet</p>}{subscriptions.map(x=><div className="line" key={x.id}><span><b>{x.physicianId}</b> • {x.reportCode}</span><button className="link" onClick={()=>show(`/subscriptions/${x.id}/fhir`)}>FHIR JSON</button></div>)}</section>
    <section className="panel"><h2>Inbound clinical reports</h2>{reports.length===0 && <p>No reports yet. Send an ORU through Mirth or use curl.</p>}{reports.map(x=><div className="line" key={x.id}><span><b>{x.physicianId}</b> • {x.reportCode}<small>{x.messageControlId}</small></span><button className="link" onClick={()=>show(`/reports/${x.id}/fhir`)}>FHIR Bundle</button></div>)}</section></div>
    <section className="panel"><h2>Pub/Sub delivery matching</h2>{deliveries.length===0 && <p>Matching events appear after a subscribed physician's report is published.</p>}{deliveries.map((x,i)=><div className="line" key={i}><span><b>{x.physicianId}</b> • report {x.reportId.slice(0,8)} • {x.reportCode}</span><small>{new Date(x.deliveredAt).toLocaleTimeString()}</small></div>)}</section>
    {selected && <section className="panel"><div className="line"><h2>HAPI-generated FHIR</h2><button onClick={()=>setSelected('')}>Close</button></div><pre>{selected}</pre></section>}
    <footer>Training simulator — no real patient data, external pub/sub credentials, authentication or encryption is configured.</footer>
  </main>;
}

createRoot(document.getElementById('root')).render(<App/>);
