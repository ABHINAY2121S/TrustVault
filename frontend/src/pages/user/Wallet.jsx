import React, { useState, useRef, useCallback } from 'react';
import {
  FileText, ShieldCheck, Clock, DownloadCloud, BookOpen, Activity, Landmark,
  Plus, Trash2, AlertTriangle, Upload, X, ScanLine, CheckCircle2
} from 'lucide-react';
import api from '../../api';

const CategoryIcon = {
  Education: <BookOpen className="w-5 h-5" />,
  Medical: <Activity className="w-5 h-5" />,
  Government: <Landmark className="w-5 h-5" />,
  Other: <FileText className="w-5 h-5" />,
};

const VerificationBadge = ({ status }) => {
  const config = {
    verified: {
      label: 'Verified',
      cls: 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/30',
      icon: <ShieldCheck className="w-3 h-3" />,
    },
    partially_verified: {
      label: 'Partially Verified',
      cls: 'bg-amber-500/10 text-amber-400 border border-amber-500/30',
      icon: <Clock className="w-3 h-3" />,
    },
    unverified: {
      label: 'Unverified',
      cls: 'bg-slate-700/40 text-slate-400 border border-slate-600/30',
      icon: <AlertTriangle className="w-3 h-3" />,
    },
  };
  const c = config[status] || config.unverified;
  return (
    <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium ${c.cls}`}>
      {c.icon}{c.label}
    </span>
  );
};

const DocumentCard = ({ doc, onDelete }) => {
  const isExpired = doc.expiryDate && new Date(doc.expiryDate) < new Date();
  const canDelete = doc.verificationStatus !== 'verified';

  return (
    <div className="glass-card-hover p-5 group relative">
      {canDelete && (
        <button
          onClick={() => onDelete(doc._id)}
          className="absolute top-3 right-3 p-1.5 rounded-lg text-slate-600 hover:text-red-400 hover:bg-red-500/10 opacity-0 group-hover:opacity-100 transition-all"
          title="Delete document"
        >
          <Trash2 className="w-3.5 h-3.5" />
        </button>
      )}
      <div className="flex justify-between items-start mb-4">
        <div className="p-3 bg-slate-800 rounded-lg text-violet-400 group-hover:scale-110 transition-transform">
          {CategoryIcon[doc.category] || CategoryIcon['Other']}
        </div>
        <VerificationBadge status={doc.verificationStatus} />
      </div>

      <h3 className="font-semibold text-slate-200 truncate pr-6" title={doc.title}>{doc.title}</h3>
      <p className="text-sm text-slate-500 mt-1">{doc.category}</p>

      {doc.issuerId && (
        <p className="text-xs text-slate-400 mt-4 flex items-center">
          <span className="text-slate-500 mr-1">Issued by:</span>
          {doc.issuerId.orgName}
        </p>
      )}

      {doc.expiryDate && (
        <p className={`text-xs mt-2 flex items-center gap-1 ${isExpired ? 'text-red-400' : 'text-slate-400'}`}>
          <Clock className="w-3 h-3" />
          {isExpired ? 'Expired' : 'Valid till'}: {new Date(doc.expiryDate).toLocaleDateString()}
        </p>
      )}

      {doc.verificationStatus === 'partially_verified' && (
        <p className="text-xs text-amber-400/70 mt-2 flex items-center gap-1">
          <ScanLine className="w-3 h-3" />
          OCR scan matched your name
        </p>
      )}
    </div>
  );
};

// Group documents by year
const groupByYear = (docs) => {
  const groups = {};
  docs.forEach(doc => {
    const year = new Date(doc.createdAt).getFullYear();
    if (!groups[year]) groups[year] = [];
    groups[year].push(doc);
  });
  return Object.entries(groups).sort(([a], [b]) => b - a);
};

const SCAN_STEPS = [
  { icon: <Upload className="w-4 h-4" />, label: 'Uploading document...' },
  { icon: <ScanLine className="w-4 h-4" />, label: 'Running OCR scan...' },
  { icon: <ShieldCheck className="w-4 h-4" />, label: 'Verifying identity...' },
  { icon: <CheckCircle2 className="w-4 h-4" />, label: 'Saving to vault...' },
];

const WalletDashboard = ({ documents, refreshDocs }) => {
  const [showUpload, setShowUpload] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [scanStep, setScanStep] = useState(-1);
  const [dragOver, setDragOver] = useState(false);
  const [selectedFile, setSelectedFile] = useState(null);
  const [form, setForm] = useState({ title: '', category: 'Other', expiryDate: '' });
  const fileRef = useRef();

  const handleFile = (file) => {
    if (!file) return;
    setSelectedFile(file);
    // Auto-fill title from filename
    const name = file.name.replace(/\.[^/.]+$/, '').replace(/[-_]/g, ' ');
    setForm(prev => ({ ...prev, title: prev.title || name }));
  };

  const handleDrop = useCallback((e) => {
    e.preventDefault();
    setDragOver(false);
    handleFile(e.dataTransfer.files[0]);
  }, []);

  const handleUpload = async (e) => {
    e.preventDefault();
    if (!selectedFile || !form.title) return;

    setUploading(true);
    setScanStep(0);

    const formData = new FormData();
    formData.append('file', selectedFile);
    formData.append('title', form.title);
    formData.append('category', form.category);
    if (form.expiryDate) formData.append('expiryDate', form.expiryDate);

    // Animate through scan steps
    const stepInterval = setInterval(() => {
      setScanStep(prev => {
        if (prev >= SCAN_STEPS.length - 2) { clearInterval(stepInterval); return prev; }
        return prev + 1;
      });
    }, 900);

    try {
      await api.post('/documents', formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      setScanStep(SCAN_STEPS.length - 1);
      setTimeout(() => {
        setShowUpload(false);
        setSelectedFile(null);
        setForm({ title: '', category: 'Other', expiryDate: '' });
        setScanStep(-1);
        refreshDocs();
      }, 1000);
    } catch (error) {
      console.error('Upload failed', error);
      setScanStep(-1);
    } finally {
      clearInterval(stepInterval);
      setUploading(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Delete this document?')) return;
    try {
      await api.delete(`/documents/${id}`);
      refreshDocs();
    } catch (err) {
      console.error(err);
    }
  };

  const yearGroups = groupByYear(documents);

  return (
    <div className="p-8 max-w-7xl mx-auto">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-3xl font-bold text-slate-100">My Document Wallet</h1>
          <p className="text-slate-400 mt-2">Manage and view your securely stored documents.</p>
        </div>
        <button onClick={() => setShowUpload(true)} className="btn-primary px-5 py-2.5 flex items-center gap-2">
          <Plus className="w-4 h-4" /> Upload Document
        </button>
      </div>

      {/* Upload Modal */}
      {showUpload && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-700 rounded-2xl p-6 w-full max-w-lg shadow-2xl">
            <div className="flex items-center justify-between mb-5">
              <h2 className="text-xl font-semibold text-slate-100 flex items-center gap-2">
                <Upload className="w-5 h-5 text-purple-400" /> Upload Local Document
              </h2>
              {!uploading && (
                <button onClick={() => { setShowUpload(false); setSelectedFile(null); setScanStep(-1); }} className="text-slate-400 hover:text-white">
                  <X className="w-5 h-5" />
                </button>
              )}
            </div>

            {uploading ? (
              /* OCR Scan Progress */
              <div className="py-6 space-y-4">
                <p className="text-slate-300 text-sm text-center mb-4">AI is scanning your document...</p>
                {SCAN_STEPS.map((step, i) => (
                  <div key={i} className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all ${
                    i < scanStep ? 'bg-emerald-500/10 border border-emerald-500/20 text-emerald-400' :
                    i === scanStep ? 'bg-purple-500/10 border border-purple-500/30 text-purple-400 animate-pulse' :
                    'bg-slate-800/40 border border-slate-700/30 text-slate-600'
                  }`}>
                    {i < scanStep ? <CheckCircle2 className="w-4 h-4 flex-shrink-0" /> : step.icon}
                    <span className="text-sm font-medium">{step.label}</span>
                  </div>
                ))}
              </div>
            ) : (
              <form onSubmit={handleUpload} className="space-y-4">
                {/* Drop Zone */}
                <div
                  onDrop={handleDrop}
                  onDragOver={(e) => { e.preventDefault(); setDragOver(true); }}
                  onDragLeave={() => setDragOver(false)}
                  onClick={() => fileRef.current?.click()}
                  className={`border-2 border-dashed rounded-xl p-6 text-center cursor-pointer transition-all ${
                    dragOver ? 'border-purple-500 bg-purple-500/10' :
                    selectedFile ? 'border-emerald-500/40 bg-emerald-500/5' : 'border-slate-700 hover:border-slate-600'
                  }`}
                >
                  <input ref={fileRef} type="file" className="hidden" accept="image/*,application/pdf" onChange={(e) => handleFile(e.target.files[0])} />
                  {selectedFile ? (
                    <div className="text-emerald-400">
                      <CheckCircle2 className="w-8 h-8 mx-auto mb-2" />
                      <p className="text-sm font-medium">{selectedFile.name}</p>
                      <p className="text-xs text-slate-500 mt-1">{(selectedFile.size / 1024).toFixed(1)} KB</p>
                    </div>
                  ) : (
                    <div className="text-slate-500">
                      <DownloadCloud className="w-8 h-8 mx-auto mb-2" />
                      <p className="text-sm">Drag & drop or <span className="text-purple-400">browse</span></p>
                      <p className="text-xs mt-1">JPEG, PNG, WebP, PDF — max 10MB</p>
                    </div>
                  )}
                </div>

                <div>
                  <label className="block text-sm text-slate-400 mb-1">Document Title</label>
                  <input
                    type="text"
                    value={form.title}
                    onChange={(e) => setForm(p => ({ ...p, title: e.target.value }))}
                    required
                    className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-2.5 text-slate-200 focus:outline-none focus:border-purple-500"
                    placeholder="e.g. Aadhaar Card"
                  />
                </div>
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-sm text-slate-400 mb-1">Category</label>
                    <select
                      value={form.category}
                      onChange={(e) => setForm(p => ({ ...p, category: e.target.value }))}
                      className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-2.5 text-slate-200 focus:outline-none focus:border-purple-500"
                    >
                      {['Education', 'Medical', 'Government', 'Other'].map(c => <option key={c}>{c}</option>)}
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm text-slate-400 mb-1">Expiry Date (optional)</label>
                    <input
                      type="date"
                      value={form.expiryDate}
                      onChange={(e) => setForm(p => ({ ...p, expiryDate: e.target.value }))}
                      className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-2.5 text-slate-200 focus:outline-none focus:border-purple-500"
                    />
                  </div>
                </div>

                <div className="p-3 bg-amber-500/10 border border-amber-500/20 rounded-xl">
                  <p className="text-xs text-amber-400 flex items-start gap-2">
                    <ScanLine className="w-3.5 h-3.5 mt-0.5 flex-shrink-0" />
                    An AI scan will extract text from your document and compare it with your profile to assign a verification level.
                  </p>
                </div>

                <div className="flex gap-3 pt-1">
                  <button type="button" onClick={() => { setShowUpload(false); setSelectedFile(null); }} className="flex-1 px-4 py-2.5 border border-slate-700 rounded-xl text-slate-400 hover:text-slate-200 hover:border-slate-500 transition-colors">
                    Cancel
                  </button>
                  <button type="submit" disabled={!selectedFile || !form.title} className="flex-1 btn-primary py-2.5 disabled:opacity-50 flex items-center justify-center gap-2">
                    <ScanLine className="w-4 h-4" /> Scan & Upload
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>
      )}

      {/* Documents grouped by year */}
      {documents.length === 0 ? (
        <div className="text-center py-24 glass-card border-dashed">
          <DownloadCloud className="w-16 h-16 mx-auto text-slate-600 mb-4" />
          <h3 className="text-xl font-semibold text-slate-300">Your wallet is empty</h3>
          <p className="text-slate-500 mt-2 max-w-md mx-auto">Upload a document or ask an institution to issue one to your TrustVault.</p>
          <button onClick={() => setShowUpload(true)} className="btn-primary mx-auto mt-6 px-5 py-2.5 flex items-center gap-2">
            <Plus className="w-4 h-4" /> Upload Document
          </button>
        </div>
      ) : (
        <div className="space-y-10">
          {yearGroups.map(([year, docs]) => (
            <div key={year}>
              <div className="flex items-center gap-4 mb-5">
                <h2 className="text-lg font-bold text-slate-300">{year}</h2>
                <div className="flex-1 h-px bg-slate-800" />
                <span className="text-xs text-slate-500">{docs.length} document{docs.length !== 1 ? 's' : ''}</span>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                {docs.map(doc => (
                  <DocumentCard key={doc._id} doc={doc} onDelete={handleDelete} />
                ))}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default WalletDashboard;
