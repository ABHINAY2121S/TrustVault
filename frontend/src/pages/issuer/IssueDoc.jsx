import React, { useState, useRef } from 'react';
import { FilePlus, ShieldCheck, Mail, Calendar, Hash, FileText, Upload, X, CheckCircle } from 'lucide-react';
import api from '../../api';
import { useNavigate } from 'react-router-dom';

const CATEGORIES = ['Education', 'Medical', 'Government', 'Other'];

const IssueDoc = ({ refreshRecords }) => {
  const [formData, setFormData] = useState({
    title: '',
    category: 'Education',
    userEmail: '',
    expiryDate: '',
    idNumber: '',
  });
  const [file, setFile] = useState(null);
  const [dragOver, setDragOver] = useState(false);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState('');
  const [error, setError] = useState('');
  const fileInputRef = useRef();
  const navigate = useNavigate();

  const handleChange = (e) => setFormData({ ...formData, [e.target.name]: e.target.value });

  const handleFile = (f) => {
    if (!f) return;
    const allowed = ['application/pdf', 'image/jpeg', 'image/png', 'image/jpg'];
    if (!allowed.includes(f.type)) {
      setError('Only PDF, JPG, or PNG files are allowed.');
      return;
    }
    if (f.size > 10 * 1024 * 1024) {
      setError('File must be under 10MB.');
      return;
    }
    setError('');
    setFile(f);
    // Auto-fill title from filename if empty
    if (!formData.title) {
      setFormData(prev => ({
        ...prev,
        title: f.name.replace(/\.[^.]+$/, '').replace(/[-_]/g, ' ')
      }));
    }
  };

  const handleDrop = (e) => {
    e.preventDefault();
    setDragOver(false);
    handleFile(e.dataTransfer.files[0]);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!file) {
      setError('Please select a document file to upload.');
      return;
    }
    setLoading(true);
    setSuccess('');
    setError('');

    try {
      const data = new FormData();
      data.append('file', file);
      data.append('title', formData.title);
      data.append('category', formData.category);
      data.append('userEmail', formData.userEmail);
      if (formData.expiryDate) data.append('expiryDate', formData.expiryDate);
      data.append('idNumber', formData.idNumber);

      await api.post('/issuer/issue', data, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });

      setSuccess('Document cryptographically signed and issued to user\'s wallet!');
      setFormData({ title: '', category: 'Education', userEmail: '', expiryDate: '', idNumber: '' });
      setFile(null);
      if (refreshRecords) refreshRecords();
      setTimeout(() => navigate('/issuer/records'), 2500);
    } catch (err) {
      setError(err.response?.data?.message || err.response?.data?.detail || 'Failed to issue document. Check the user email.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="p-8 max-w-4xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-slate-100 flex items-center">
          <ShieldCheck className="w-8 h-8 mr-3 text-emerald-500" />
          Issue Digital Document
        </h1>
        <p className="text-slate-400 mt-2">Upload a PDF or image and cryptographically sign it for a user.</p>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-2xl shadow-xl overflow-hidden">
        <div className="p-1 bg-gradient-to-r from-emerald-500 to-teal-500" />
        <div className="p-8">

          {success && (
            <div className="mb-6 p-4 bg-emerald-500/10 border border-emerald-500/50 rounded-lg text-emerald-400 flex items-center gap-3">
              <CheckCircle className="w-5 h-5 flex-shrink-0" />
              {success}
            </div>
          )}
          {error && (
            <div className="mb-6 p-4 bg-red-500/10 border border-red-500/50 rounded-lg text-red-400">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-6">
            {/* File Upload */}
            <div>
              <label className="block text-sm font-medium text-slate-400 mb-2 flex items-center">
                <FilePlus className="w-4 h-4 mr-2" /> Document File <span className="text-red-400 ml-1">*</span>
              </label>

              {file ? (
                <div className="flex items-center gap-3 bg-emerald-500/10 border border-emerald-500/40 rounded-xl p-4">
                  <div className="flex-shrink-0 w-10 h-10 bg-emerald-500/20 rounded-lg flex items-center justify-center">
                    <FileText className="w-5 h-5 text-emerald-400" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-emerald-300 font-medium truncate">{file.name}</p>
                    <p className="text-emerald-500/70 text-sm">{(file.size / 1024).toFixed(1)} KB</p>
                  </div>
                  <button type="button" onClick={() => setFile(null)} className="text-slate-500 hover:text-red-400 transition-colors">
                    <X className="w-5 h-5" />
                  </button>
                </div>
              ) : (
                <div
                  onDragOver={(e) => { e.preventDefault(); setDragOver(true); }}
                  onDragLeave={() => setDragOver(false)}
                  onDrop={handleDrop}
                  onClick={() => fileInputRef.current.click()}
                  className={`cursor-pointer border-2 border-dashed rounded-xl p-8 text-center transition-all ${
                    dragOver
                      ? 'border-emerald-500 bg-emerald-500/10'
                      : 'border-slate-700 hover:border-slate-500 hover:bg-slate-800/50'
                  }`}
                >
                  <Upload className="w-10 h-10 text-slate-500 mx-auto mb-3" />
                  <p className="text-slate-300 font-medium">Click or drag & drop to upload</p>
                  <p className="text-sm text-slate-500 mt-1">PDF, JPG, or PNG — max 10MB</p>
                </div>
              )}
              <input
                ref={fileInputRef}
                type="file"
                accept=".pdf,.jpg,.jpeg,.png"
                className="hidden"
                onChange={(e) => handleFile(e.target.files[0])}
              />
            </div>

            {/* Form fields */}
            <div className="grid md:grid-cols-2 gap-6">
              <div>
                <label className="block text-sm font-medium text-slate-400 mb-2 flex items-center">
                  <FileText className="w-4 h-4 mr-2" /> Document Title <span className="text-red-400 ml-1">*</span>
                </label>
                <input
                  required type="text" name="title"
                  value={formData.title} onChange={handleChange}
                  className="w-full bg-slate-950 border border-slate-700 rounded-lg px-4 py-2.5 text-slate-200 focus:ring-1 focus:ring-emerald-500 outline-none transition-all placeholder:text-slate-600"
                  placeholder="e.g. Bachelor's Degree Certificate"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-400 mb-2 flex items-center">
                  <Mail className="w-4 h-4 mr-2" /> Recipient User Email <span className="text-red-400 ml-1">*</span>
                </label>
                <input
                  required type="email" name="userEmail"
                  value={formData.userEmail} onChange={handleChange}
                  className="w-full bg-slate-950 border border-slate-700 rounded-lg px-4 py-2.5 text-slate-200 focus:ring-1 focus:ring-emerald-500 outline-none transition-all placeholder:text-slate-600"
                  placeholder="user@example.com"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-400 mb-2">Category</label>
                <select
                  name="category" value={formData.category} onChange={handleChange}
                  className="w-full bg-slate-950 border border-slate-700 rounded-lg px-4 py-2.5 text-slate-200 outline-none focus:ring-1 focus:ring-emerald-500"
                >
                  {CATEGORIES.map(c => <option key={c}>{c}</option>)}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-400 mb-2 flex items-center">
                  <Hash className="w-4 h-4 mr-2" /> Reference / ID Number <span className="text-slate-600 text-xs ml-1">(optional)</span>
                </label>
                <input
                  type="text" name="idNumber"
                  value={formData.idNumber} onChange={handleChange}
                  className="w-full bg-slate-950 border border-slate-700 rounded-lg px-4 py-2.5 text-slate-200 focus:ring-1 focus:ring-emerald-500 outline-none transition-all placeholder:text-slate-600"
                  placeholder="e.g. UNI-2024-8923"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-400 mb-2 flex items-center">
                  <Calendar className="w-4 h-4 mr-2" /> Expiry Date (Optional)
                </label>
                <input
                  type="date" name="expiryDate"
                  value={formData.expiryDate} onChange={handleChange}
                  className="w-full bg-slate-950 border border-slate-700 rounded-lg px-4 py-2.5 text-slate-400 focus:ring-1 focus:ring-emerald-500 outline-none transition-all"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading || !file}
              className="w-full py-3.5 bg-emerald-600 hover:bg-emerald-500 disabled:opacity-50 disabled:cursor-not-allowed text-white font-bold rounded-lg transition-colors flex items-center justify-center gap-2 shadow-lg shadow-emerald-900/20"
            >
              {loading ? (
                <>
                  <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  Signing & Issuing...
                </>
              ) : (
                <>
                  <ShieldCheck className="w-5 h-5" />
                  Cryptographically Sign & Issue
                </>
              )}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};

export default IssueDoc;
