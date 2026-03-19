import React, { useState, useEffect, useRef } from 'react';
import {
  ScanLine, Link as LinkIcon, ShieldCheck, Loader2, XCircle,
  FolderOpen, FileText, Clock, CheckCircle, XOctagon, User,
  Calendar, Building2, ExternalLink, Image as ImageIcon, FileImage
} from 'lucide-react';
import { Html5QrcodeScanner } from 'html5-qrcode';
import api from '../../api';

const BACKEND = 'http://192.168.1.4:5000';

// ─── Step indicator ────────────────────────────────────────────────────────
const Step = ({ n, label, active, done }) => (
  <div className="flex items-center gap-2">
    <div className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold transition-all
      ${done ? 'bg-emerald-500 text-white' : active ? 'bg-indigo-500 text-white' : 'bg-slate-800 text-slate-500'}`}>
      {done ? '✓' : n}
    </div>
    <span className={`text-sm font-medium ${active ? 'text-slate-200' : done ? 'text-emerald-400' : 'text-slate-500'}`}>
      {label}
    </span>
  </div>
);

// ─── Document card (full detail) ───────────────────────────────────────────
const DocCard = ({ doc }) => {
  const [expanded, setExpanded] = useState(false);
  const categoryColor = {
    Education:  'text-blue-400 bg-blue-400/10 border-blue-400/20',
    Medical:    'text-green-400 bg-green-400/10 border-green-400/20',
    Government: 'text-amber-400 bg-amber-400/10 border-amber-400/20',
  }[doc.category] ?? 'text-purple-400 bg-purple-400/10 border-purple-400/20';

  const statusColor = doc.verificationStatus === 'verified'
    ? 'text-emerald-400 bg-emerald-400/10' : 'text-amber-400 bg-amber-400/10';

  const fmtDate = (d) => d ? new Date(d).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }) : 'Lifetime';
  const isExpired = doc.expiryDate && new Date(doc.expiryDate) < new Date();

  const fileUrl = doc.fileUrl?.startsWith('/uploads/')
    ? `${BACKEND}${doc.fileUrl}` : null;
  const isImage = fileUrl && /\.(jpg|jpeg|png|webp|gif)$/i.test(fileUrl);
  const isPdf   = fileUrl && /\.pdf$/i.test(fileUrl);

  return (
    <div className="bg-slate-900 rounded-2xl border border-slate-800 overflow-hidden">
      {/* Card header */}
      <div className="p-5">
        <div className="flex items-start gap-4">
          <div className="p-2.5 bg-indigo-500/10 rounded-xl shrink-0">
            <FileText className="w-5 h-5 text-indigo-400" />
          </div>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 flex-wrap mb-2">
              <h4 className="font-semibold text-slate-100 text-base">{doc.title}</h4>
              <span className={`text-xs px-2 py-0.5 rounded-full font-medium border ${categoryColor}`}>
                {doc.category}
              </span>
              <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${statusColor}`}>
                {doc.verificationStatus === 'verified' ? '✓ Verified' : doc.verificationStatus}
              </span>
            </div>

            <div className="grid grid-cols-2 gap-x-6 gap-y-2 text-sm">
              <div className="flex items-center gap-2 text-slate-400">
                <Building2 className="w-3.5 h-3.5 shrink-0" />
                <span className="text-slate-300">{doc.issuerId?.orgName || 'Self uploaded'}</span>
              </div>
              {doc.issuerId?.orgType && (
                <div className="flex items-center gap-2 text-slate-400">
                  <User className="w-3.5 h-3.5 shrink-0" />
                  <span>{doc.issuerId.orgType}</span>
                </div>
              )}
              <div className="flex items-center gap-2 text-slate-400">
                <Calendar className="w-3.5 h-3.5 shrink-0" />
                <span>Issued: <span className="text-slate-300">{fmtDate(doc.createdAt)}</span></span>
              </div>
              <div className="flex items-center gap-2 text-slate-400">
                <Calendar className="w-3.5 h-3.5 shrink-0" />
                <span>Expires: <span className={isExpired ? 'text-red-400' : 'text-slate-300'}>{fmtDate(doc.expiryDate)}</span></span>
              </div>
            </div>

            {/* Metadata */}
            {doc.metadata && Object.keys(doc.metadata).length > 0 && (
              <div className="mt-3 pt-3 border-t border-slate-800 grid grid-cols-2 gap-x-6 gap-y-1.5 text-xs">
                {Object.entries(doc.metadata).map(([k, v]) => v && (
                  <div key={k}>
                    <span className="text-slate-500">{k}: </span>
                    <span className="text-slate-300">{String(v)}</span>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Document preview */}
      {fileUrl && (
        <div className="border-t border-slate-800">
          {isImage ? (
            <div>
              {expanded ? (
                <div className="p-3">
                  <img src={fileUrl} alt={doc.title} className="w-full rounded-xl max-h-96 object-contain bg-slate-950" />
                </div>
              ) : (
                <button onClick={() => setExpanded(true)}
                  className="w-full py-3 flex items-center justify-center gap-2 text-sm text-indigo-400 hover:bg-slate-800 transition-colors">
                  <ImageIcon className="w-4 h-4" />
                  View Document Image
                </button>
              )}
            </div>
          ) : isPdf ? (
            <a href={fileUrl} target="_blank" rel="noreferrer"
              className="flex items-center justify-center gap-2 py-3 text-sm text-indigo-400 hover:bg-slate-800 transition-colors">
              <ExternalLink className="w-4 h-4" />
              Open PDF Document
            </a>
          ) : (
            <a href={fileUrl} target="_blank" rel="noreferrer"
              className="flex items-center justify-center gap-2 py-3 text-sm text-indigo-400 hover:bg-slate-800 transition-colors">
              <ExternalLink className="w-4 h-4" />
              View Document
            </a>
          )}
        </div>
      )}
    </div>
  );
};

// ─── Main Verify page ──────────────────────────────────────────────────────
const Verify = () => {
  const [activeTab, setActiveTab]     = useState('link');
  const [tokenInput, setTokenInput]   = useState('');
  const [loading, setLoading]         = useState(false);
  const [error, setError]             = useState('');

  // Step 1 → form, Step 2 → waiting for approval, Step 3 → approved/denied
  const [step, setStep]               = useState(1);
  const [verifierName, setVerifierName] = useState('');
  const [verifierOrg, setVerifierOrg]   = useState('');
  const [requestId, setRequestId]     = useState(null);
  const [pollStatus, setPollStatus]   = useState('pending'); // 'pending' | 'approved' | 'denied'
  const [resource, setResource]       = useState(null);

  const pollRef = useRef(null);

  // Auto-fill from URL ?token=...
  useEffect(() => {
    const t = new URLSearchParams(window.location.search).get('token');
    if (t) setTokenInput(t);
  }, []);

  // Cleanup polling on unmount
  useEffect(() => () => clearInterval(pollRef.current), []);

  const extractToken = (input) => {
    try { return new URL(input).searchParams.get('token') || input.trim(); }
    catch { return input.trim(); }
  };

  // ── Step 1: Send access request ──────────────────────────────────────────
  const sendRequest = async (e) => {
    e.preventDefault();
    if (!tokenInput.trim()) return;
    setLoading(true); setError('');
    const token = extractToken(tokenInput);
    try {
      const res = await api.post('/access/request', {
        token,
        verifierName: verifierName || 'A Verifier',
        verifierEmail: verifierOrg || '',
      });
      setRequestId(res.data.requestId);
      setStep(2);
      startPolling(res.data.requestId);
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to send request. Check the token.');
    } finally {
      setLoading(false);
    }
  };

  // ── Step 2: Poll until approved/denied ───────────────────────────────────
  const startPolling = (reqId) => {
    setPollStatus('pending');
    pollRef.current = setInterval(async () => {
      try {
        const res = await api.get(`/access/check/${reqId}`);
        if (res.data.status === 'approved') {
          clearInterval(pollRef.current);
          setResource(res.data.resource);
          setPollStatus('approved');
          setStep(3);
        } else if (res.data.status === 'denied') {
          clearInterval(pollRef.current);
          setPollStatus('denied');
          setStep(3);
        }
      } catch { /* keep polling */ }
    }, 3000);
  };

  const reset = () => {
    clearInterval(pollRef.current);
    setStep(1); setError(''); setTokenInput('');
    setRequestId(null); setResource(null);
    setPollStatus('pending'); setVerifierName(''); setVerifierOrg('');
  };

  // QR scanner
  useEffect(() => {
    let scanner;
    if (activeTab === 'qr' && step === 1 && !loading) {
      scanner = new Html5QrcodeScanner('qr-reader', { fps: 10, qrbox: { width: 250, height: 250 } }, false);
      scanner.render((text) => {
        scanner.clear();
        setTokenInput(text);
      }, () => {});
    }
    return () => { if (scanner) scanner.clear().catch(() => {}); };
  }, [activeTab, step, loading]);

  return (
    <div className="p-8 max-w-3xl mx-auto">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-slate-100 flex items-center gap-3">
          <ScanLine className="w-8 h-8 text-indigo-500" />
          Verify Document
        </h1>
        <p className="text-slate-400 mt-2">
          Enter a share link or scan a QR code to request access to documents.
        </p>
      </div>

      {/* Step indicator */}
      <div className="flex items-center gap-3 mb-8">
        <Step n={1} label="Enter Token" active={step === 1} done={step > 1} />
        <div className="flex-1 h-px bg-slate-800" />
        <Step n={2} label="Awaiting Approval" active={step === 2} done={step > 2} />
        <div className="flex-1 h-px bg-slate-800" />
        <Step n={3} label="View Documents" active={step === 3} done={false} />
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-2xl shadow-xl overflow-hidden">

        {/* ── STEP 1: Input ── */}
        {step === 1 && (
          <>
            {/* Tabs */}
            <div className="flex border-b border-slate-800">
              {[['link', <LinkIcon className="w-4 h-4 mr-2" />, 'Paste Link / Token'],
                ['qr',  <ScanLine  className="w-4 h-4 mr-2" />, 'Scan QR Code']
              ].map(([id, icon, label]) => (
                <button key={id} onClick={() => setActiveTab(id)}
                  className={`flex-1 py-4 text-sm font-medium transition-colors flex justify-center items-center
                    ${activeTab === id ? 'bg-indigo-600/10 text-indigo-400 border-b-2 border-indigo-500' : 'text-slate-400 hover:text-slate-300'}`}>
                  {icon}{label}
                </button>
              ))}
            </div>

            <div className="p-8">
              {activeTab === 'link' ? (
                <form onSubmit={sendRequest} className="space-y-4">
                  <div>
                    <label className="block text-sm text-slate-400 mb-2">Share link or token *</label>
                    <input type="text" value={tokenInput} onChange={(e) => setTokenInput(e.target.value)}
                      placeholder="Paste the full link or bare token..." required
                      className="w-full bg-slate-950 border border-slate-700 rounded-xl px-4 py-3 text-slate-200 focus:ring-1 focus:ring-indigo-500 outline-none text-sm" />
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm text-slate-400 mb-2">Your name *</label>
                      <input type="text" value={verifierName} onChange={(e) => setVerifierName(e.target.value)}
                        placeholder="e.g. Ravi Kumar" required
                        className="w-full bg-slate-950 border border-slate-700 rounded-xl px-4 py-3 text-slate-200 focus:ring-1 focus:ring-indigo-500 outline-none text-sm" />
                    </div>
                    <div>
                      <label className="block text-sm text-slate-400 mb-2">Organization / Email</label>
                      <input type="text" value={verifierOrg} onChange={(e) => setVerifierOrg(e.target.value)}
                        placeholder="e.g. Infosys HR"
                        className="w-full bg-slate-950 border border-slate-700 rounded-xl px-4 py-3 text-slate-200 focus:ring-1 focus:ring-indigo-500 outline-none text-sm" />
                    </div>
                  </div>

                  {error && (
                    <div className="p-4 bg-red-500/10 border border-red-500/30 rounded-xl text-red-400 text-sm flex items-center gap-3">
                      <XCircle className="w-5 h-5 shrink-0" />
                      {error}
                    </div>
                  )}

                  <button type="submit" disabled={loading}
                    className="w-full py-3 bg-indigo-600 hover:bg-indigo-500 disabled:opacity-50 text-white rounded-xl font-medium transition-colors flex items-center justify-center gap-2">
                    {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : <ShieldCheck className="w-4 h-4" />}
                    {loading ? 'Sending request...' : 'Request Access'}
                  </button>
                </form>
              ) : (
                <div className="max-w-md mx-auto">
                  <div id="qr-reader" className="w-full bg-slate-950 rounded-xl overflow-hidden border border-slate-700" />
                  {tokenInput && (
                    <div className="mt-4 p-3 bg-emerald-500/10 border border-emerald-500/20 rounded-xl text-emerald-400 text-sm break-all">
                      ✓ QR scanned. Fill in your details and request access.
                    </div>
                  )}
                  {tokenInput && (
                    <form onSubmit={sendRequest} className="mt-4 space-y-3">
                      <div className="grid grid-cols-2 gap-3">
                        <input type="text" value={verifierName} onChange={(e) => setVerifierName(e.target.value)}
                          placeholder="Your name *" required
                          className="bg-slate-950 border border-slate-700 rounded-xl px-4 py-2.5 text-slate-200 outline-none text-sm focus:ring-1 focus:ring-indigo-500" />
                        <input type="text" value={verifierOrg} onChange={(e) => setVerifierOrg(e.target.value)}
                          placeholder="Organization"
                          className="bg-slate-950 border border-slate-700 rounded-xl px-4 py-2.5 text-slate-200 outline-none text-sm focus:ring-1 focus:ring-indigo-500" />
                      </div>
                      <button type="submit" disabled={loading}
                        className="w-full py-3 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl font-medium flex items-center justify-center gap-2">
                        {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : <ShieldCheck className="w-4 h-4" />}
                        Request Access
                      </button>
                    </form>
                  )}
                </div>
              )}
            </div>
          </>
        )}

        {/* ── STEP 2: Waiting for approval ── */}
        {step === 2 && (
          <div className="p-12 text-center">
            <div className="relative inline-block mb-6">
              <div className="w-20 h-20 rounded-full bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center mx-auto">
                <Clock className="w-9 h-9 text-indigo-400" />
              </div>
              <Loader2 className="w-6 h-6 text-indigo-400 animate-spin absolute -bottom-1 -right-1" />
            </div>
            <h3 className="text-xl font-semibold text-slate-200 mb-2">Waiting for approval</h3>
            <p className="text-slate-400 text-sm max-w-sm mx-auto mb-6">
              The document owner has been notified of your request. This page will update automatically when they respond.
            </p>
            <div className="inline-flex items-center gap-2 bg-amber-500/10 border border-amber-500/20 text-amber-400 text-sm px-4 py-2 rounded-full">
              <span className="w-1.5 h-1.5 rounded-full bg-amber-400 animate-pulse" />
              Checking every 3 seconds...
            </div>
            <div className="mt-6">
              <button onClick={reset} className="text-slate-500 hover:text-slate-400 text-sm transition-colors">
                Cancel request
              </button>
            </div>
          </div>
        )}

        {/* ── STEP 3: Result ── */}
        {step === 3 && (
          <div className="p-8">
            {/* Denied */}
            {pollStatus === 'denied' && (
              <div className="text-center py-8">
                <div className="w-16 h-16 bg-red-500/10 rounded-full flex items-center justify-center mx-auto mb-4">
                  <XOctagon className="w-8 h-8 text-red-400" />
                </div>
                <h3 className="text-xl font-semibold text-slate-200 mb-2">Access Denied</h3>
                <p className="text-slate-400 text-sm">The document owner has declined your request.</p>
                <button onClick={reset} className="mt-6 text-indigo-400 hover:text-indigo-300 text-sm font-medium transition-colors">
                  ← Try again
                </button>
              </div>
            )}

            {/* Approved */}
            {pollStatus === 'approved' && resource && (
              <div>
                {/* Banner */}
                <div className="bg-emerald-500/10 border border-emerald-500/30 rounded-2xl p-5 text-center mb-7 relative overflow-hidden">
                  <div className="absolute top-0 right-0 w-24 h-24 bg-emerald-500/10 rounded-full blur-2xl -mr-6 -mt-6" />
                  <CheckCircle className="w-12 h-12 text-emerald-500 mx-auto mb-3" />
                  <h2 className="text-xl font-bold text-emerald-400 mb-1">
                    {resource.type === 'folder' ? `Folder: "${resource.folder?.name}"` : 'Document Access Granted'}
                  </h2>
                  <p className="text-emerald-500/70 text-sm">
                    {resource.type === 'folder'
                      ? `${resource.documents?.length || 0} document(s) shared with you`
                      : 'Document verified and shared by the owner'}
                  </p>
                </div>

                {/* Folder: list of docs */}
                {resource.type === 'folder' && (
                  <div className="space-y-4">
                    {resource.folder && (
                      <div className="flex items-center gap-2 mb-4">
                        <FolderOpen className="w-5 h-5 text-purple-400" />
                        <span className="font-semibold text-slate-200 text-lg">{resource.folder.name}</span>
                        <span className="text-xs text-slate-500 ml-auto">{resource.documents?.length} document(s)</span>
                      </div>
                    )}
                    {(resource.documents || []).map((doc) => <DocCard key={doc._id} doc={doc} />)}
                  </div>
                )}

                {/* Single document */}
                {resource.type === 'document' && resource.document && (
                  <DocCard doc={resource.document} />
                )}

                <div className="text-center mt-8">
                  <button onClick={reset} className="text-indigo-400 hover:text-indigo-300 text-sm font-medium transition-colors">
                    ← Verify another document
                  </button>
                </div>
              </div>
            )}
          </div>
        )}

      </div>
    </div>
  );
};

export default Verify;
