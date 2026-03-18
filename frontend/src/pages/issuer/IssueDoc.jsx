import React, { useState } from 'react';
import { FilePlus, ShieldCheck, Mail, Calendar, Hash, FileText } from 'lucide-react';
import api from '../../api';
import { useNavigate } from 'react-router-dom';

const IssueDoc = ({ refreshRecords }) => {
  const [formData, setFormData] = useState({
    title: '',
    category: 'Education',
    userEmail: '',
    expiryDate: '',
    idNumber: '',
  });
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState('');
  const [error, setError] = useState('');
  const navigate = useNavigate();

  const handleChange = (e) => setFormData({ ...formData, [e.target.name]: e.target.value });

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setSuccess('');
    setError('');

    try {
      await api.post('/issuer/issue', {
        title: formData.title,
        category: formData.category,
        userEmail: formData.userEmail,
        expiryDate: formData.expiryDate || null,
        fileUrl: `https://mockstorage.com/${Date.now()}.pdf`, // Mock URL for MVP
        metadata: {
          'ID Number': formData.idNumber,
          'Issued On': new Date().toISOString()
        }
      });
      setSuccess('Document securely signed and issued successfully!');
      setFormData({ title: '', category: 'Education', userEmail: '', expiryDate: '', idNumber: '' });
      refreshRecords();
      setTimeout(() => navigate('/issuer/records'), 2000);
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to issue document');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="p-8 max-w-4xl mx-auto">
      <div className="mb-8 flex items-start justify-between">
        <div>
          <h1 className="text-3xl font-bold text-slate-100 flex items-center">
            <ShieldCheck className="w-8 h-8 mr-3 text-emerald-500" />
            Issue Digital Document
          </h1>
          <p className="text-slate-400 mt-2">Cryptographically sign and assign a document to a user's wallet.</p>
        </div>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-2xl shadow-xl overflow-hidden">
        <div className="p-1 bg-gradient-to-r from-emerald-500 to-teal-500"></div>
        <div className="p-8">
          
          {success && (
            <div className="mb-6 p-4 bg-emerald-500/10 border border-emerald-500/50 rounded-lg text-emerald-400 flex items-center">
              <ShieldCheck className="w-5 h-5 mr-3 flex-shrink-0" />
              {success}
            </div>
          )}
          
          {error && (
            <div className="mb-6 p-4 bg-red-500/10 border border-red-500/50 rounded-lg text-red-400">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="grid md:grid-cols-2 gap-6">
              <div>
                <label className="block text-sm font-medium text-slate-400 mb-2 flex items-center">
                  <FileText className="w-4 h-4 mr-2" /> Document Title
                </label>
                <input required type="text" name="title" value={formData.title} onChange={handleChange} className="w-full bg-slate-950 border border-slate-700 rounded-lg px-4 py-2.5 text-slate-200 focus:ring-1 focus:ring-emerald-500 outline-none transition-all placeholder:text-slate-600" placeholder="e.g. Master's Degree Certificate" />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-slate-400 mb-2 flex items-center">
                  <Mail className="w-4 h-4 mr-2" /> Recipient User Email
                </label>
                <input required type="email" name="userEmail" value={formData.userEmail} onChange={handleChange} className="w-full bg-slate-950 border border-slate-700 rounded-lg px-4 py-2.5 text-slate-200 focus:ring-1 focus:ring-emerald-500 outline-none transition-all placeholder:text-slate-600" placeholder="user@example.com" />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-slate-400 mb-2">Category</label>
                <select name="category" value={formData.category} onChange={handleChange} className="w-full bg-slate-950 border border-slate-700 rounded-lg px-4 py-2.5 text-slate-200 outline-none">
                  <option>Education</option>
                  <option>Medical</option>
                  <option>Government</option>
                  <option>Other</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-400 mb-2 flex items-center">
                  <Hash className="w-4 h-4 mr-2" /> Reference / ID Number
                </label>
                <input required type="text" name="idNumber" value={formData.idNumber} onChange={handleChange} className="w-full bg-slate-950 border border-slate-700 rounded-lg px-4 py-2.5 text-slate-200 focus:ring-1 focus:ring-emerald-500 outline-none transition-all placeholder:text-slate-600" placeholder="e.g. RN-894239" />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-400 mb-2 flex items-center">
                  <Calendar className="w-4 h-4 mr-2" /> Expiry Date (Optional)
                </label>
                <input type="date" name="expiryDate" value={formData.expiryDate} onChange={handleChange} className="w-full bg-slate-950 border border-slate-700 rounded-lg px-4 py-2.5 text-slate-400 focus:ring-1 focus:ring-emerald-500 outline-none transition-all" />
              </div>
            </div>

            <div className="pt-6 border-t border-slate-800">
              <div className="bg-slate-950 border border-dashed border-slate-700 rounded-xl p-8 text-center flex flex-col items-center justify-center">
                <FilePlus className="w-10 h-10 text-slate-500 mb-3" />
                <p className="text-slate-300 font-medium">Upload Document File</p>
                <p className="text-sm text-slate-500 mt-1">PDF or Image up to 5MB (Mocked for MVP)</p>
              </div>
            </div>

            <button type="submit" disabled={loading} className="w-full py-3.5 bg-emerald-600 hover:bg-emerald-500 disabled:opacity-50 text-white font-bold rounded-lg transition-colors flex items-center justify-center shadow-lg shadow-emerald-900/20">
              {loading ? 'Processing Crypto Signature...' : 'Cryptographically Sign & Issue'}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};

export default IssueDoc;
